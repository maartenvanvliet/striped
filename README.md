# Striped
## [![Hex pm](http://img.shields.io/hexpm/v/striped.svg?style=flat)](https://hex.pm/packages/striped) [![Hex Docs](https://img.shields.io/badge/hex-docs-9768d1.svg)](https://hexdocs.pm/striped) [![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) ![.github/workflows/test.yml](https://github.com/maartenvanvliet/striped/actions/workflows/test.yml/badge.svg)
<!-- MDOC !-->

Library to interface with the Stripe Api. Most of the code is generated from the [Stripe OpenApi](https://github.com/stripe/openapi) definitions.

Inspiration was drawn from [Stripity Stripe](https://github.com/beam-community/stripity_stripe) and [openapi](https://github.com/wojtekmach/openapi).

## Installation

```elixir
def deps do
  [
    {:striped, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
client = Stripe.new(api_key: "sk_test_123")
{:ok, %Stripe.Customer{}} = Stripe.Customer.retrieve(client, "cus123")

{:ok, %Stripe.Customer{}} =
               Stripe.Customer.create(client, %{
                 description: "Test description"
               })

```

For the exact parameters you can consult the Stripe docs.

### Errors
Stripe errors can be found in the `Stripe.ApiErrors` struct. 
Network errors etc. will be found in the error term.

```elixir
{:error, %Stripe.ApiErrors{}} =
               Stripe.Customer.retrieve(client, "bogus")
```              

### Api Version
`Striped` uses the OpenApi definitions to build itself, so it 
uses the latest Api Version. You can however override the 
version by passing the `:version` option to the client.

### Limitations

  * File Uploads currently don't work. 
  * TypeSpecs for functions are not complete. Automatically generating them leads to very verbose specs. This will need some additional work to be more idiomatic.
  * Connected Accounts are not supported yet. 