# Striped
## [![Hex pm](http://img.shields.io/hexpm/v/striped.svg?style=flat)](https://hex.pm/packages/striped) [![Hex Docs](https://img.shields.io/badge/hex-docs-9768d1.svg)](https://hexdocs.pm/striped) [![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)![.github/workflows/elixir.yml](https://github.com/maartenvanvliet/striped/workflows/.github/workflows/test.yml/badge.svg)
<!-- MDOC !-->

Library to interface with the Stripe Api. Most of the code is generated from the [Stripe OpenApi](https://github.com/stripe/openapi) definitions.

Inspiration was drawn from [StripityStripe](https://github.com/beam-community/stripity_stripe) and [openapi](https://github.com/wojtekmach/openapi).

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

