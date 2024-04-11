require "weak_ref"

# :nodoc:
#
# A hash that holds weak references to its values. When a value is garbage
# collected, the key is removed from the hash. Thread-safe.
class Crystal::WeakHash(K, V)
  # The number of garbage collected values before the hash is cleaned up.
  COLLECT_INTERVAL = 15

  def initialize
    @mutex = Crystal::SpinLock.new
    @death_count = 0
    @hash = {} of K => WeakRef(V)
  end

  def [](key : K) : V
    @mutex.sync do
      cleanup
      @hash[key].value.not_nil!
    end
  end

  # Note that the value might be nil because the key doesn't exist or because
  # the value was garbage collected.
  def []?(key : K) : V?
    @mutex.sync do
      cleanup
      @hash[key]?.try &.value
    end
  end

  def delete(key : K)
    @mutex.sync do
      cleanup
      @hash.delete(key)
    end
  end

  def []=(key : K, value : V)
    @mutex.sync do
      {% if V.has_method? "finalize" %}
        LibGC.register_finalizer(value.as(Void*),
          ->(obj, data) {
            data.as(WeakHash(K, V)).register_death
            obj.as(V).finalize
          },
          self.as(Void*), nil, nil)
      {% else %}
        LibGC.register_finalizer(value.as(Void*),
          ->(obj, data) {
            data.as(WeakHash(K, V)).register_death
          },
          self.as(Void*), nil, nil)
      {% end %}
      @hash[key] = WeakRef.new value
    end
  end

  def each_value(& : V ->)
    @mutex.sync do
      cleanup
      @hash.each_value do |weak_ref|
        value = weak_ref.value
        yield value if value
      end
    end
  end

  private def cleanup
    if @death_count > COLLECT_INTERVAL
      @death_count = 0
      @hash.reject! { |k, v| v.value.nil? }
    end
  end

  protected def register_death
    # no need to synch the counter, it's just an approximation
    @death_count += 1
  end
end
