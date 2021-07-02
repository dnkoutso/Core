module Pod
  # The LocalSource class is responsible to manage a collection of podspecs from a given path.
  #
  class LocalSource < Source
    def url
      "file://#{repo}"
    end

    def type
      'file system'
    end

    def specs_dir
      repo
    end

    def pod_path(_name)
      repo
    end

    def metadata_path
      nil
    end

    def pods
      unless specs_dir.exist?
        raise Informative, "Unable to find a source named: `#{name}`"
      end
      @pods ||= all_specs.map(&:name).uniq.sort
    end

    def pods_for_specification_paths(_spec_paths)
      # This method is invoked for updating a search index which local sources dont support.
      []
    end

    def versions(name)
      return @versions_by_name[name] if @versions_by_name.key?(name)
      specs = all_specs.select { |s| s.name == name }
      return if specs.empty?
      @versions_by_name[name] ||= specs.map(&:version).compact.sort.reverse
    end

    def specification_path(name, version)
      spec = all_specs.find do |s|
        # ADD A TEST
        s.name == name && s.version == Pod::Version.create(version)
      end
      if spec.nil?
        raise StandardError, "Unable to find the specification #{name} " \
          "(#{version}) in the #{self.name} source."
      end
      Pathname.new(spec.defined_in_file).expand_path
    end

    def all_specs
      @all_specs ||= begin
                       glob = specs_dir.join('**/*.podspec{.json,}')
                       specs = Pathname.glob(glob).map do |path|
                         begin
                           Specification.from_file(path)
                         rescue
                           CoreUI.warn "Skipping `#{path.relative_path_from(repo)}` because the " \
                      'podspec contains errors.'
                           next
                         end
                       end
                       specs.compact
                     end
    end

    def search(query)
      unless specs_dir
        raise Informative, "Unable to find a source named: `#{name}`"
      end
      if query.is_a?(Dependency)
        query = query.root_name
      end

      Specification::Set.new(query, self) if all_specs.any? { |s| s.name == query }
    end

    def update(_show_output)
      []
    end

    def updateable?
      false
    end

    def git?
      false
    end

    def local?
      true
    end

    def indexable?
      false
    end

    def verify_compatibility!
    end

    private

    def refresh_metadata
    end
  end
end
