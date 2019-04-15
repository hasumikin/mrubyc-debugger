# mrubyc-debugger

mrubyc-debugger is a TUI (test user interface) for developing [mruby/c](https://github.com/mrubyc/mrubyc) application. It runs mruby/c loops as CRuby Threads on your terminal.

'loop' is, in short, infinite loop like `while true; hoge(); end` .

Caution: This gem is still experimental and not released yet.

## Demo

![demo](https://raw.githubusercontent.com/wiki/hasumikin/mrubyc-debugger/images/demo-1.gif)

## Usage

- h:←, j:↓, k:↑, l:→ move the cursor to select a line
- SPACE toggles on and off of a breakpoint on the line which the cursor points

## Features

- TUI (text user interface) powered by [Curses](https://github.com/ruby/curses)
- Visualize your loops, their local variables and debug printing of `puts`
- Originally mrubyc-debugger was designed for the sake of mruby/c application. But you may be able to use it to see CRuby's multi threads program, especially for learning Thread class

## Features in future (possibly)

- Much more colorful. Like syntax highlighting
- Cooperation with [mrubyc-test](https://github.com/hasumikin/mrubyc-test)
  - Using stub and mock declarations in test cases to simulate an integrated circumstance

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
This means you have `.mrubycconfig` file in your top directory of your project.

Besides, you have to locate mruby loop files that are the target of debugging like `mrblib/loops/main.rb`

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
│      └── loops                # Place your loop files here
│            ├── main.rb        # A loop something like awaiting for user input
│            └── sub.rb         # Another loop eg) BLE status observation, LED blinking, etc.
├── mrubyc-debugger.yml         # You can configure stub methods in form of YAML
└── sdkconfig
```

At the top directory:

    $ mrubyc-debugger

To make your loops slow:

    $ mrubyc-debugger --delay 1

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hasumikin/mrubyc-debugger. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Mrubyc::Debugger project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/hasumikin/mrubyc-debugger/blob/master/CODE_OF_CONDUCT.md).
