module PuppetDocs

  module Reference

    # Find the special versions that should be symlinked
    def self.special_versions
      listing = {}
      listing[:stable] = generated_versions.detect { |v, dir| v.release_type == :final }
      listing[:latest] = generated_versions.first
      # This looks super hairy, so here's the deal: We have an array of
      # arrays, w/ each internal array containing a Versionomy::Value object and
      # a directory. Whole thing is sorted by the versionomy objects. Since it's
      # sorted, we are guaranteed that, every time the major.minor value of the
      # version objects CHANGES, we're looking at the latest reference from that
      # particular major.minor series. So we'll just cache all those! This gives
      # us self-maintaining 2.7.latest, etc. links, which is rad.
      prev_maj_min = "0.0"
      generated_versions.each do |ver_dir_pair|
        v = ver_dir_pair[0]
        clump = "#{v.major}.#{v.minor}"
        if clump != prev_maj_min
          listing["#{clump}.latest"] = ver_dir_pair
          prev_maj_min = clump
        end
      end
      listing
    end

    # A sorted array of [version, path] for non-symlinked version paths
    def self.generated_versions #:nodoc:
      return @generated_versions if @generated_versions
      possibles = generated_version_directories.map do |path|
        [Versionomy.parse(path.basename.to_s), path]
      end
      @generated_versions = possibles.sort_by { |x| x.first }.reverse
    end

    # The valid, non-symlinked version paths
    def self.generated_version_directories #:nodoc:
      children = (PuppetDocs.root + "source/references").children
      possibles = children.select do |child|
        child.directory? && !child.symlink?
      end
    end

    class Generator

      def initialize(tag, name)
        @tag = tag
        @name = name
        setup_repository!
        validate!
        change_to_tag!
      end

      def generate

        ENV['RUBYLIB'] = "#{facter_dir}/lib:#{hiera_dir}/lib:#{puppet_dir}/lib"

        puts "Generating #{@name} reference for #{version}."

        if @name == "developer"
          Dir.chdir(puppet_dir)
          puts "(YARD documentation takes a while to generate.)"
          `bundle exec yard -o #{yard_directory}`
          return
        end

        content = `ruby #{puppet_dir}/bin/puppet doc --modulepath /tmp/nothing --libdir /tmp/alsonothing -m text -r #{@name}`

        if content
          if @name == "configuration" # then get any references to the laptop's hostname out of there
            require 'facter'
            hostname = Facter["hostname"].value
            domain = Facter["domain"].value
            if domain and domain != ""
              fqdn = [hostname, domain].join(".")
            else
              fqdn = hostname
            end
            content.gsub!(fqdn.downcase, "(the system's fully qualified domain name)")
            # Yuck, this next one is hard to deal with when the domain is "local," like a Mac on a DNS-less network. Will have to be very specific, which makes it kind of brittle.
            content.gsub!("- *Default*: #{domain.downcase}\n", "- *Default*: (the system's own domain)\n")
          elsif @name == "type"
            # make the feature table headers less garbage
            content.gsub!(/^Provider(?-m:\s+|.*)$/) {|headerline|
              headerline.gsub('_', ' ')
            }
            # fix the useradd provider to be kinda-sorta-usually-true instead of
            # locally-absolutely-true-but-useless-to-real-users. Line 95 of
            # lib/puppet/provider/user/useradd.rb says:
            #   has_features :manages_passwords, :manages_password_age if Puppet.features.libshadow?
            # This means useradd can't manage passwords if you don't have ruby
            # libshadow installed. You can't have libshadow installed on the laptops
            # we generate the docs with. We always publish docs that say
            # useradd can't manage passwords. This is locally true but the opposite
            # of what nearly all real users experience.

            # This depends on the specific structure of the providers table for
            # the user type, so we're basically hoping they don't add more
            # features. This is terrible but there's not an easy solution that's better.

            # We want to change cells 6 and 8 of the row that starts with useradd.
            content.sub!(/^(useradd *\| *\*X\* *\| *\| *\*X\* *\| *\*X\* *\| )   ( *\| *\| )   ( *\| *\| *\*X\* *\|)/, '\1*X*\2*X*\3')

          end

          setup_destination!
          File.open(destination_filename, 'w') { |f| f.write content }
          File.open(destination_filename).read() =~ /\# (.*)\n/
          title = $1
          file = IO.read(destination_filename)
          header = <<EOT
---
layout: default
title: "#{title}"
canonical: "/references/latest/#{@name}.html"
---
EOT
          open(destination_filename, 'w') { |f| f << header << "\n\n" << file}
          puts "Wrote #{destination_filename}"
         else
          abort "Could not build #{@name} reference using puppetdoc at #{version}"
        end
      end

      private

      def valid_tags
        %x{git fetch --tags origin}
        @valid_tags ||= at('master') { `git tag` }.grep(/\./).map { |s| s.strip }
      end

      def version
        @version ||=
          at @tag do
            raw = `ruby  -rpuppet -e 'puts Puppet::PUPPETVERSION'`.strip
            Versionomy.parse(raw)
          end
      end

      def validate!
        unless valid_tags.include?(@tag)
          abort "Invalid puppet tag: #{@tag}"
        end
      end

      def at(ref, &block)
        Dir.chdir(puppet_dir) do
          %x{git reset --hard #{ref}}
          if $?.success?
            yield if block_given?
          else
            abort "Could not switch to '#{ref}'"
          end
        end
      end

      def puppet_dir
        PuppetDocs.root + 'vendor/puppet'
      end

      def hiera_dir
        PuppetDocs.root + 'vendor/hiera'
      end

      def facter_dir
        PuppetDocs.root + 'vendor/facter'
      end


      def setup_repository!

        if File.directory?(puppet_dir)
          at 'master' do
            %x{git pull origin master}
          end
        else
          puts "Retrieving puppet source."
          %x{git clone git://github.com/puppetlabs/puppet.git '#{puppet_dir}'}
        end

        if File.directory?(facter_dir)
           Dir.chdir(facter_dir)
            %x{git pull origin master}
        else
          puts "Retrieving facter source."
          %x{git clone git://github.com/puppetlabs/facter.git '#{facter_dir}'}
        end

        if File.directory?(hiera_dir)
             Dir.chdir(hiera_dir)
            %x{git pull origin master}
        else
          puts "Retrieving hiera source."
          %x{git clone git://github.com/puppetlabs/hiera.git '#{hiera_dir}'}
        end

      end

      def change_to_tag!
        at @tag
      end

      def destination_filename
        @destination_filename ||= destination_directory + (@name + ".markdown")
      end

      def destination_directory
        @destination_directory ||= PuppetDocs.root + "source/references" + @tag
      end

     def yard_directory
        @yard_directory ||= destination_directory + "developer"
      end

      def setup_destination!
        destination_directory.mkpath
      end

    end

  end

end
