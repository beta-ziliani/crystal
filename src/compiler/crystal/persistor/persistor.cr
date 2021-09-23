require "../syntax/to_s"
require "../program.cr"

module Crystal
  class Persistor
    # def visit(node : Require)
    #   if expanded = node.expanded
    #     expanded.accept self
    #     return false
    #   else
    #     raise "visit Require should've been expanded"
    #   end
    # end

    def self.persist(io, arr : Array(Const))
      arr = arr.reject &.value.is_a?(Primitive)

      arr.each do |c|
        io << c.name
        io << " = "
        c.value.to_s io
        io << "\n"
      end
    end

    def self.persist(io, arr : Array(ClassVarInitializer))
      arr.each do |c|
        io << c.name
        io << " = "
        c.node.to_s io
        io << "\n"
      end
    end

    def self.persist(io, program : Program)
      persist io, program.const_initializers
      # persist io, program.class_var_initializers
    end

    def self.persist(io, program : Program, node : ASTNode)
      persist(io, program)
      node.to_s io
    end

    def self.persist(program : Program, node : ASTNode)
      String.build do |io|
        persist(io, program, node)
      end
    end
  end
end
