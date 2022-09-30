defmodule Striped.MixProject do
  use Mix.Project

  @url "https://github.com/maartenvanvliet/striped"

  def project do
    [
      app: :striped,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @url,
      homepage_url: @url,
      name: "Striped",
      description:
        "Stripe Api SDK generated from OpenApi definitions.",
      package: [
        maintainers: ["Maarten van Vliet"],
        licenses: ["MIT"],
        links: %{"GitHub" => @url},
        files: ~w(LICENSE README.md lib priv mix.exs .formatter.exs)
      ],
      docs: [
        main: "Stripe",
        source_url: @url,
        canonical: "http://hexdocs.pm/striped",
        groups_for_modules: [
          "Core Resources": [
            Stripe.Balance,
            Stripe.BalanceTransaction,
            Stripe.Charge,
            Stripe.Customer,
            Stripe.Dispute,
            Stripe.Event,
            Stripe.ExchangeRate,
            Stripe.File,
            Stripe.FileLink,
            Stripe.Mandate,
            Stripe.PaymentIntent,
            Stripe.PaymentSource,
            Stripe.SetupIntent,
            Stripe.SetupAttempt,
            Stripe.Payout,
            Stripe.Refund,
            Stripe.Token
          ],
          "Payment Methods": [
            Stripe.ApplePayDomain,
            Stripe.PaymentMethod,
            Stripe.BankAccount,
            Stripe.CashBalance,
            Stripe.Card,
            Stripe.Source,
            Stripe.SourceTransaction
          ],
          Products: [
            Stripe.Product,
            Stripe.Price,
            Stripe.Coupon,
            Stripe.PromotionCode,
            Stripe.Discount,
            Stripe.Item,
            Stripe.TaxCode,
            Stripe.TaxId,
            Stripe.TaxRate,
            Stripe.ShippingRate
          ],
          Checkout: [
            Stripe.Checkout.Session,
            Stripe.Order,
            Stripe.Sku
          ],
          "Payment Links": [
            Stripe.PaymentLink
          ],
          Billing: [
            Stripe.BillingPortal.Configuration,
            Stripe.BillingPortal.Session,
            Stripe.CreditNote,
            Stripe.CreditNoteLineItem,
            Stripe.CustomerBalanceTransaction,
            Stripe.CustomerCashBalanceTransaction,
            Stripe.Invoice,
            Stripe.Invoiceitem,
            Stripe.LineItem,
            Stripe.Plan,
            Stripe.Quote,
            Stripe.Subscription,
            Stripe.SubscriptionItem,
            Stripe.SubscriptionSchedule,
            Stripe.TestHelpers.TestClock,
            Stripe.UsageRecord,
            Stripe.UsageRecordSummary
          ],
          Connect: [
            Stripe.Account,
            Stripe.AccountLink,
            Stripe.ApplicationFee,
            Stripe.Capability,
            Stripe.CountrySpec,
            Stripe.ExternalAccount,
            Stripe.FeeRefund,
            Stripe.LoginLink,
            Stripe.Person,
            Stripe.Topup,
            Stripe.Transfer,
            Stripe.TransferReversal,
            Stripe.Apps.Secret
          ],
          Fraud: [
            Stripe.Radar.EarlyFraudWarning,
            Stripe.Review,
            Stripe.Radar.ValueList,
            Stripe.Radar.ValueListItem
          ],
          Issuing: [
            Stripe.EphemeralKey,
            Stripe.Issuing.Authorization,
            Stripe.Issuing.Cardholder,
            Stripe.Issuing.Card,
            Stripe.Issuing.Dispute,
            Stripe.FundingInstructions,
            Stripe.Issuing.Transaction
          ],
          Terminal: [
            Stripe.Terminal.ConnectionToken,
            Stripe.Terminal.Location,
            Stripe.Terminal.Reader,
            Stripe.Terminal.Configuration
          ],
          Treasury: [
            Stripe.Treasury.FinancialAccount,
            Stripe.Treasury.FinancialAccountFeatures,
            Stripe.Treasury.Transaction,
            Stripe.Treasury.TransactionEntry,
            Stripe.Treasury.OutboundTransfer,
            Stripe.Treasury.OutboundPayment,
            Stripe.Treasury.InboundTransfer,
            Stripe.Treasury.ReceivedCredit,
            Stripe.Treasury.ReceivedDebit,
            Stripe.Treasury.CreditReversal,
            Stripe.Treasury.DebitReversal
          ],
          Sigma: [
            Stripe.ScheduledQueryRun
          ],
          Reporting: [
            Stripe.Reporting.ReportRun,
            Stripe.Reporting.ReportType
          ],
          "Financial Connections": [
            Stripe.FinancialConnections.Account,
            Stripe.FinancialConnections.AccountOwner,
            Stripe.FinancialConnections.Session
          ],
          Identify: [
            Stripe.Identity.VerificationSession,
            Stripe.Identity.VerificationReport
          ],
          Webhooks: [
            Stripe.WebhookEndpoint
          ],
          "Deleted Entities": [
            Stripe.DeletedAccount,
            Stripe.DeletedApplePayDomain,
            Stripe.DeletedCoupon,
            Stripe.DeletedCustomer,
            Stripe.DeletedDiscount,
            Stripe.DeletedExternalAccount,
            Stripe.DeletedInvoice,
            Stripe.DeletedInvoiceitem,
            Stripe.DeletedPaymentSource,
            Stripe.DeletedPerson,
            Stripe.DeletedPlan,
            Stripe.DeletedProduct,
            Stripe.DeletedRadar.ValueList,
            Stripe.DeletedRadar.ValueListItem,
            Stripe.DeletedSku,
            Stripe.DeletedSubscriptionItem,
            Stripe.DeletedTaxId,
            Stripe.DeletedTerminal.Configuration,
            Stripe.DeletedTerminal.Location,
            Stripe.DeletedTerminal.Reader,
            Stripe.DeletedTestHelpers.TestClock,
            Stripe.DeletedWebhookEndpoint
          ]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.3.0"},
      {:ex_doc, "~> 0.28"},
      {:uri_query, "~> 0.1.2"}
    ]
  end
end
