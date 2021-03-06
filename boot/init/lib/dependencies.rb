module Dependencies
  class BaseDependency
    def fulfilled?()
      true
    end

    def name()
      self.class.name
    end

    def depends_on?(other)
      raise "#{self.class.name} has to implement #depends_on?"
    end
  end

  class Task < BaseDependency
    def initialize(instance)
      @instance = instance
    end

    def fulfilled?()
      if @instance.ran
        true
      else
        $logger.debug(" -> Dependency #{name} unfulfilled? (task #{@instance.inspect} hasn't run yet)")
        false
      end
    end

    def depends_on?(other)
      @instance.depends_on?(other)
    end
  end

  # When any of the dependencies given have been fulfilled, this dependency
  # will be fulfilled.
  class Any < BaseDependency
    def initialize(*dependencies)
      @dependencies = dependencies
    end

    def fulfilled?()
      @dependencies.any? { |dependency| dependency.fulfilled? }
    end

    def depends_on?(other)
      @dependencies.any? { |dependency| dependency.depends_on?(other) }
    end
  end

  class Files < BaseDependency
    def initialize(*patterns)
      @patterns = *patterns
    end

    def fulfilled?()
      if @patterns.all? { |pattern| Dir.glob(pattern).count > 0 }
        true
      else
        $logger.debug do
          patterns = @patterns.reject do |pattern|
            Dir.glob(pattern).count > 0
          end.join(", ")

          " -> Dependency #{name} unfulfilled? (Pattern #{patterns} does not match paths)"
        end
        false
      end
    end

    # It is unknown what creates the file.
    # For mount points, prefer the +Mount+ dependency type.
    def depends_on?(other)
      false
    end
  end

  # Checks in sysfs for the given network interface names.
  class NetworkInterface < Files
    def initialize(*names)
      super(*names.map { |name| File.join("/sys/class/net", name) })
    end
  end

  class Target < BaseDependency
    def initialize(name)
      @name = name.to_sym
    end

    def fulfilled?()
      task.ran
    end

    def depends_on?(other)
      task.depends_on?(other)
    end

    def task()
      Targets[@name]
    end
  end
end
