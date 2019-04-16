module Danger
  # Lint javascript files using [golint](http://golint.org/).
  # Results are send as inline commen.
  #
  # @example Run golint with changed files only
  #
  #          golint.filtering = true
  #          golint.lint
  #
  # @see  leonhartX/danger-golint
  # @tags lint, golang, golint
  class DangerGolint < Plugin
    # Root directory from where golint will run.
    # Defaults to current directory.
    # @return [String]
    attr_writer :base_dir

    MARKDOWN_TEMPLATE = \
      '## DangerGo found issues\n\n'\
      '| File | Line | Column | Reason |\n'\
      '|------|------|--------|--------|\n'.freeze

    def base_dir
      @base_dir || '.'
    end

    # Lints go files.
    # Generates `errors` and `warnings` due to golint's config.
    # Will try to send inline comment if supported(Github)
    #
    # @return  [void]
    #
    def lint
      errors = lint_results.reject(&:nil?)

      return if errors.empty?

      print_markdown_table(errors)
    end

    private

    # Check existing status golint toolchain
    # #
    # @return [bool]
    def golint_installed?
      `which golint`.strip.empty? == false
    end

    # Get lint result regards the filtering option
    #
    # return [Hash]
    def lint_results
      bin = 'golint'
      system 'go get -u golang.org/x/lint/golint' unless golint_installed?
      run_lint(bin, base_dir)
    end

    # Run golint aginst a single dir.
    #
    # @param   [String] bin
    #          The binary path of golint
    #
    # @param   [String] dir
    #          Dir to be linted
    #
    # @return [Output]
    def run_lint(bin, dir)
      `#{bin} #{dir}`.split('\n')
    end

    # Print markdown string
    #
    # @param   [List<string>] errors
    #
    # @return  [string]
    def print_markdown_table(errors=[])
      report = errors.inject(MARKDOWN_TEMPLATE) do |out, error_line|
        file, line, column, reason = error_line.split(':')
        out + "| #{short_link(file, line)} | #{line} | #{column} | #{reason.strip.tr('\'', '`')} |\n"
      end

      markdown(report)
    end

    def short_link(file, line)
      if danger.scm_provider.to_s == 'github'
        return github.html_link("#{file}#L#{line}", full_path: false)
      end

      file
    end
  end
end
