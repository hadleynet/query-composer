# When jasmine starts the server out-of-process, it needs this in order to be able to invoke the asset tasks.
# This step, along with the coffeescript compilation for jasmine is borrowed and modified from Jeff Dean's blog post
# http://pivotallabs.com/users/jdean/blog/articles/1778-writing-and-running-jasmine-specs-with-rails-3-1-and-coffeescript
unless Object.const_defined?(:Rake)
  require 'rake'
  load File.expand_path('../../../../Rakefile', __FILE__)
end

module Jasmine
  class Config

    def js_files(spec_filter = nil)
      precompile_app_assets
      compile_jasmine_javascripts

      # This is code from the original jasmine config js_files method - you could also just alias_method_chain it
      spec_files_to_include = spec_filter.nil? ? spec_files : match_files(spec_dir, [spec_filter])
      src_files.collect {|f| "/" + f } + helpers.collect {|f| File.join(spec_path, f) } + spec_files_to_include.collect {|f| File.join(spec_path, f) }
    end

    private

    # This method compiles all the same javascript files the app naturally will
    def precompile_app_assets
      #puts "Precompiling assets..."
    
      # Make sure the Rails environment is loaded
      #::Rake.application['environment'].invoke

      # Temporarily set the static assets location from public/assets to our spec directory
      #Rails.application.config.assets.prefix = "../spec/javascripts/generated"
      #Rails.application.config.assets.manifest = File.join(Rails.public_path, Rails.application.config.assets.prefix)

      # Rake won't let you run the same task twice in the same process without re-enabling it
      # so reenable the "clean" task and run it
      #::Rake.application['assets:clean'].reenable
      #::Rake.application['assets:clean'].invoke

      # Once the assets have been cleared, recompile them into the spec directory
      #::Rake.application['assets:precompile'].reenable
      #::Rake.application['assets:precompile'].invoke
    end

    # This method compiles all of the spec files into js files that jasmine can run
    def compile_jasmine_javascripts
      puts "Removing previously compiled jasmine coffeescript..."
      generated_directory = File.dirname(File.expand_path("../../generated/", __FILE__))
      Dir.foreach(generated_directory) do |file|
        if file != generated_directory && file == '.' && file == '..'
          if File.directory?(file)
            FileUtils.rm_rf(file)
          else
            FileUtils.rm(file)
          end
        end
      end
      
      Dir.mkdir(File.dirname(File.expand_path("../../generated/javascripts", __FILE__))) unless File.exists?(File.dirname(File.expand_path("../../generated/javascripts", __FILE__)))
      Dir.mkdir(File.dirname(File.expand_path("../../generated/specs", __FILE__))) unless File.exists?(File.dirname(File.expand_path("../../generated/specs", __FILE__)))
      
      root = File.expand_path("../../../../app/assets/javascripts/builder", __FILE__)
      destination_dir = File.expand_path("../../generated/javascripts", __FILE__)
      glob = File.expand_path("**/*.js.coffee", root)
      Dir.glob(glob).each do |srcfile|
        srcfile = Pathname.new(srcfile)
        destfile = srcfile.sub(root, destination_dir).sub(".coffee", "")
        FileUtils.mkdir_p(destfile.dirname)
        File.open(destfile, "w") {|f| f.write(CoffeeScript.compile(File.new(srcfile)))}
      end
      
      root = File.expand_path("../../../../spec/javascripts/specs", __FILE__)
      destination_dir = File.expand_path("../../generated/specs", __FILE__)
      glob = File.expand_path("**/*.js.coffee", root)
      Dir.glob(glob).each do |srcfile|
        srcfile = Pathname.new(srcfile)
        destfile = srcfile.sub(root, destination_dir).sub(".coffee", "")
        FileUtils.mkdir_p(destfile.dirname)
        File.open(destfile, "w") {|f| f.write(CoffeeScript.compile(File.new(srcfile)))}
      end
    end

  end
end


# Note - this is necessary for rspec2, which has removed the backtrace
module Jasmine
  class SpecBuilder
    def declare_spec(parent, spec)
      me = self
      example_name = spec["name"]
      @spec_ids << spec["id"]
      backtrace = @example_locations[parent.description + " " + example_name]
      parent.it example_name, {} do
        me.report_spec(spec["id"])
      end
    end
  end
end
