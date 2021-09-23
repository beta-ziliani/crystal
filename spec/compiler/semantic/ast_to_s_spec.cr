require "../../spec_helper"

private def semantic(s : String)
  semantic s, inject_primitives: false, cleanup: false
end

{% for type in ["class", "struct", "module"] %}
describe "to_s a {{type.id}}" do
  it "that is empty" do
    sr = semantic %(
      {{type.id}} A
      end
      )
    sr.node.to_s.should eq <<-STR
      {{type.id}} A
      end
      STR
  end

  {% unless type == "module" %}
  it "with an initialized field" do
    sr = semantic %(
      {{type.id}} A
        @a = ""
        def a
          @a
        end
      end
      )
    sr.node.to_s.should eq <<-STR
      {{type.id}} A
        @a = ""
        def a
          @a
        end
      end
      STR
  end
  {% end %}

  it "with an uninitialized field" do
    sr = semantic %(
      {{type.id}} A
        def a
          @a
        end
      end
      )
    sr.node.to_s.should eq <<-STR
      {{type.id}} A
        def a
          @a
        end
      end
      STR
  end

  it "with an initialized class variable" do
    sr = semantic %(
      {{type.id}} A
        @@a = ""
        def self.a
          @@a
        end
      end
      )
    s = Persistor.persist(sr.program, sr.node)
    s.should eq <<-STR
      {{type.id}} A
        @@a = ""
        def self.a
          @@a
        end
      end
      STR
  end

  it "with a constant" do
    sr = semantic %(
      {{type.id}} A
        A_CONST = ""
      end
      )
    s = Persistor.persist(sr.program, sr.node)
    s.should eq <<-STR
      {{type.id}} A
        A_CONST = ""
      end
      STR
  end

  it "with a protected def" do
    sr = semantic %(
      {{type.id}} A
        protected def a
          "this is protected"
        end
      end
      )
    s = Persistor.persist(sr.program, sr.node)
    s.should eq <<-STR
      {{type.id}} A
        protected def a
          "this is protected"
        end
      end
      STR
  end

  it "that is private" do
    sr = semantic %(
      private {{type.id}} A
      end
      )
    s = Persistor.persist(sr.program, sr.node)
    s.should eq <<-STR
      private {{type.id}} A
      end
      STR
  end

  it "with a macro" do
    sr = semantic %(
      {{type.id}} A
        macro test
        end
      end
      )
    s = Persistor.persist(sr.program, sr.node)
    # TODO: indentation is wrong
    s.should eq <<-STR
      {{type.id}} A
        macro test
                end
      end
      STR
  end
end
{% end %}

it "to_s a class including a module with an initialized variable" do
  sr = semantic %(
    module A
      @a = ""
      def a
        @a
      end
    end

    class B
    include A
    end
    )
  s = Persistor.persist(sr.program, sr.node)
  s.should eq <<-STR
    module A
      @a = ""
      def a
        @a
      end
    end
    class B
      include A
    end\n
    STR
  # HACK: No idea why it needs that '\n' here
end

it "to_s the pointer type" do
  sr = semantic %(
    Pointer(Void)
    )
  s = Persistor.persist(sr.program, sr.node)
  s.should eq <<-STR
    Pointer(Void)
    STR
end

it "to_s args, respecting the name" do
  sr = semantic %(
    def f(a_name : String)
      a_name
    end
    f a_name: "hi"
    )
  s = Persistor.persist(sr.program, sr.node)
  s.should eq <<-STR
    def f(a_name : String)
      a_name
    end
    f(a_name: "hi")\n
    STR
end

it "to_s a splat" do
  sr = semantic %(
    def f(*elements)
      elements
    end
    f "hi"
    )
  s = Persistor.persist(sr.program, sr.node)
  s.should eq <<-STR
    def f(*elements)
      elements
    end
    f("hi")\n
    STR
end

it "to_s default args" do
  sr = semantic %(
    def f(a_name = "hi")
      a_name
    end
    f
    )
  s = Persistor.persist(sr.program, sr.node)
  s.should eq <<-STR
    def f(a_name = "hi")
      a_name
    end
    f\n
    STR
end

it "to_s named args after a splat" do
  sr = semantic %(
    def f(*, a_name : String)
      a_name
    end
    f a_name: "hi"
    )
  s = Persistor.persist(sr.program, sr.node)
  s.should eq <<-STR
    def f(*, a_name : String)
      a_name
    end
    f(a_name: "hi")\n
    STR
end
