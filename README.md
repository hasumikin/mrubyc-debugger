# Mrubyc::Debugger

mrubyc-debugger is a TUI (test user interface) for developing [mruby/c](https://github.com/mrubyc/mrubyc) application. It runs mruby/c tasks () CRuby ::Thread on your terminal.
'task' is a term of microcontrollers. In short, infinite loop like `while true; hoge(); end` .

## Demo

![demo](https://raw.githubusercontent.com/wiki/hasumikin/mrubyc-debugger/images/demo-1.gif)

## Features

- TUI (text user interface) powered by [Curses](https://github.com/ruby/curses)
- Visualize your tasks, its local variables and debug printing of `puts`
- Originally mrubyc-debugger was designed for the sake of mruby/c application. But you may be able to use it to see CRuby's multi threads program, especially for learning Thread class

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mrubyc-debugger'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mrubyc-debugger

## Usage

Assuming you are using [mrubyc-utils](https://github.com/hasumikin/mrubyc-utils) to manage your project and [rbenv](https://github.com/rbenv/rbenv) to manage Ruby versions.
This means you have `.mrubycconfig` file in your top directory.

Besides, you have to locate mruby task files that are the target of debugging like `mrblib/tasks/main.rb`

This is an example of ESP32 project:

```
~/your_project $ tree
.
├── .mrubycconfig                # Created by mrubyc-utils
├── Makefile
├── build
├── components
├── main
├── mrblib
│      └── models
│            ├── class_name.rb  # models are tested by mrubyc-test
│            └── my_class.rb    # models are tested by mrubyc-test
│      └── tasks                # Place your task files here
│            ├── main.rb        # A task something like awaiting for user input
│            └── sub.rb         # Another task eg) BLE status observation, LED blinking, etc.
└── sdkconfig
```

At the top directory:

    $ mrubyc-debugger

To make your tasks slow:

    $ mrubyc-debugger --delay 1

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/mrubyc-debugger. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Mrubyc::Debugger project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/mrubyc-debugger/blob/master/CODE_OF_CONDUCT.md).
