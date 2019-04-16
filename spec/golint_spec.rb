require File.expand_path('spec_helper', __dir__)

module Danger
  describe Danger::DangerGolint do
    it 'should be a plugin' do
      expect(Danger::DangerGolint.new(nil)).to be_a Danger::Plugin
    end

    #
    # You should test your custom attributes and methods here
    #
    describe 'with Dangerfile' do
      before do
        @dangerfile = testing_dangerfile
        @golint = @dangerfile.golint
      end

      context 'golint not installed' do
        before do
          allow(@golint).to receive(:`).with('which golint').and_return('')
        end
      end

      context 'golint installed' do
        before do
          allow(@golint).to receive(:`).with('which golint').and_return('/usr/bin/golint')
        end

        describe 'lint' do
          it 'runs lint from current directory by default' do
            expect(@golint).to receive(:`).with('golint .').and_return('')
            @golint.lint
          end

          it 'runs lint from a custom directory' do
            expect(@golint).to receive(:`).with('golint my/custom/directory').and_return('')

            @golint.base_dir = 'my/custom/directory'
            @golint.lint
          end

          it 'handles a lint with no errors' do
            allow(@golint).to receive(:`).with('golint .').and_return('')
            @golint.lint
            expect(@golint.status_report[:markdowns].first).to be_nil
          end
        end

        context 'when running on github' do
          it 'handles a lint with errors count greater than threshold' do
            lint_report = "test.go:213:3: don't use underscores in Go names; var my_var should be myVar\n" \
              "test.go:217:3: var testUrl should be testUrl\n"

            allow(@golint).to receive(:`).with('golint .').and_return(lint_report)
            allow(@dangerfile.danger).to receive(:scm_provider).and_return('github')
            allow(@dangerfile.github).to receive(:html_link)
              .with('test.go#L213', full_path: false)
              .and_return('fake_link_to:test.go#L213')
            allow(@dangerfile.github).to receive(:html_link)
              .with('test.go#L217', full_path: false)
              .and_return('fake_link_to:test.go#L217')

            @golint.lint

            markdown = @golint.status_report[:markdowns].first
            expect(markdown.message).to include('## DangerGo found issues')
            expect(markdown.message).to include("| fake_link_to:test.go#L213 | 213 | 3 | " \
              "don`t use underscores in Go names; var my_var should be myVar |\n" \
              "| fake_link_to:test.go#L217 | 217 | 3 | var testUrl should be testUrl |")
          end
        end
      end
    end
  end
end
