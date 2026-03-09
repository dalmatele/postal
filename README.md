![GitHub Header](https://github.com/postalserver/.github/assets/4765/7a63c35d-2f47-412f-a6b3-aebc92a55310)

**Postal** is a complete and fully featured mail server for use by websites & web servers. Think Sendgrid, Mailgun or Postmark but open source and ready for you to run on your own servers. 

* [Documentation](https://docs.postalserver.io)
* [Installation Instructions](https://docs.postalserver.io/getting-started)
* [FAQs](https://docs.postalserver.io/welcome/faqs) & [Features](https://docs.postalserver.io/welcome/feature-list)
* [Discussions](https://github.com/postalserver/postal/discussions) - ask for help or request a feature
* [Join us on Discord](https://discord.postalserver.io)

# Config
* We use lib\postal\config_schema.rb to manage config variables of system. You must define config variable in this file before using it.
* To install ruby 3.2.2 in macos 15.5, run bellow command before install

`export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)"`

# How to run

* Set the environment for project by add variable Postal::Config.rails.environment to postal.yml file

`bundle exec postal web-server`

# Other resources
https://guides.rubyonrails.org/active_record_basics.html
