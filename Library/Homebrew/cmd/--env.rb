require 'extend/ENV'
require 'hardware'

module Homebrew extend self
  def __env
    ENV.extend(HomebrewEnvExtension)
    ENV.setup_build_environment
    ENV.universal_binary if ARGV.build_universal?
    ARGV.formulae.each do |f|
      # NOTE: Copied from build.rb def install (line ~63)
      # TODO: Refactor to have a single instance of this code.
      if dep.keg_only?
        ENV.prepend 'LDFLAGS', "-L#{dep.lib}"
        ENV.prepend 'CPPFLAGS', "-I#{dep.include}"
        ENV.prepend 'PATH', "#{dep.bin}", ':'

        pcdir = dep.lib/'pkgconfig'
        ENV.prepend 'PKG_CONFIG_PATH', pcdir, ':' if pcdir.directory?

        acdir = dep.share/'aclocal'
        ENV.prepend 'ACLOCAL_PATH', acdir, ':' if acdir.directory?
      end
    end
    if $stdout.tty?
      dump_build_env ENV
    else
      build_env_keys(ENV).each do |key|
        puts "export #{key}=\"#{ENV[key]}\""
      end
    end
  end

  def build_env_keys env
    %w[ CC CXX LD CFLAGS CXXFLAGS CPPFLAGS LDFLAGS MACOSX_DEPLOYMENT_TARGET
      MAKEFLAGS PKG_CONFIG_PATH HOMEBREW_BUILD_FROM_SOURCE HOMEBREW_DEBUG
      HOMEBREW_MAKE_JOBS HOMEBREW_VERBOSE HOMEBREW_USE_CLANG HOMEBREW_USE_GCC
      HOMEBREW_USE_LLVM HOMEBREW_SVN ].select{ |key| env[key] }
  end

  def dump_build_env env
    build_env_keys(env).each do |key|
      value = env[key]
      print "#{key}: #{value}"
      case key when 'CC', 'CXX', 'LD'
        if value =~ %r{/usr/bin/xcrun (.*)}
          path = `/usr/bin/xcrun -find #{$1}`
          print " => #{path}"
        elsif File.symlink? value
          print " => #{Pathname.new(value).realpath}"
        end
      end
      puts
    end
  end
end
