# VintageNet WiFi Configuration Wizard

[![CircleCI](https://circleci.com/gh/nerves-networking/vintage_net_wizard.svg?style=svg)](https://circleci.com/gh/nerves-networking/vintage_net_wizard)
[![Coverage Status](https://coveralls.io/repos/github/nerves-networking/vintage_net_wizard/badge.svg?branch=master)](https://coveralls.io/github/nerves-networking/vintage_net_wizard?branch=master)
[![Hex version](https://img.shields.io/hexpm/v/vintage_net_wizard.svg "Hex version")](https://hex.pm/packages/vintage_net_wizard)

This is a WiFi configuration wizard that uses
[VintageNet](https://github.com/nerves-networking/vintage_net). It is intended
for use in Nerves-based devices that don't have a display for configuring WiFi.

Here's the intended use:

1. On device initialization, if WiFi hasn't been configured, configure WiFi to
   AP mode and start a webserver
2. A user connects to the access point and opens a web browser. The only
   website they can go to in the configuration utility.
3. The configuration utility shows a list of access points and the user can
   select one or more or enter information for a hidden access point
4. The user applies the configuration and the device stops AP mode and connects
   to the access point.

`VintageNet` persists WiFi configuration so the device will be able to connect
after reboots and power outages. To change the configuration later, a user needs
to take a device-specific action like hold down a button for 5 seconds. This
library has an example project for the Raspberry Pi for use as a demo.

![see it in action](assets/vintage_net_wizard.gif)

## Features

* [x] - Simple web-based configuration utility
* [x] - WiFi scanning while in AP mode
* [x] - JSON REST-based API to support smartphone app-based configuration
* [ ] - Captive portal - the webserver is at a static IP address, but it
  currently won't trigger captive portal detection
* [x] - WPA PSK configuration
* [ ] - WPA EAP configuration
* [x] - Hidden AP configuration
* [x] - Multiple AP selection (device tries access points in order until one
  works)
* [ ] - Custom styling and branding

## Supported WiFi adapters

Not all WiFi adapters support AP mode. Here are the ones that we've used:

1. Raspberry Pis with built-in WiFi modules (like the RPi 3, 4 and Zero W)
2. RT5370-based USB modules

It is highly likely that other modules work. We have not had any luck with
the Realtek RTL8192c (in the popular Edimax EW7811Un) or MediaTek MT7601u (in
lots of brands).

## Configuration

It is expected that you're using
[`VintageNet`](https://github.com/nerves-networking/vintage_net) already. If
you're not, see that project first.

`VintageNetWizard` is an OTP application so it's mostly self-contained. Add it
to your `mix` dependencies like so:

```elixir
   {:vintage_net_wizard, "~> 0.1"}
```

The configuration wizard is not started by default to allow for more control
over business specific situations. You will need to add a call in your code
when you want the device placed into AP mode and the wizard started:

```elixir
defmodule MyApp do
  use Application

  def start(_type, _args) do
    if should_start_wizard?() do
      VintageNetWizard.run_wizard
    end
    # ...
    Supervisor.start_link(children, opts)
  end
end
```

This will be sufficient to try it out on a device that hasn't been configured
yet. You will want to add a mechanism for forcing the wizard the run WiFi
configuration again, such as holding a button for 5+ seconds. Take a look at
[Running the example](#running-the-example) section for steps on setting up
a button and running a quick example firmware on a device.

### DNS in AP-mode

When the wizard is running, users go to either `http://192.168.0.1/` or
`http://wifi.config/` to access the web user interface. The latter can be
changed via the `config.exs`:

```elixir
config :vintage_net_wizard,
  dns_name: "my-wifi-config.com"
```

### Port

`VintageNetWizard` starts a webserver on port `80` by default. If port `80` is
not available on your device or you would prefer a different port, add the
following to your `config.exs`:

```elixir
config :vintage_net_wizard,
  port: 4001
```

If SSL is enabled the default port is `443`.

### SSL

To use SSL with the web UI, you can pass SSL options to
`VintageNetWizard.run_wizard/1`:

```elixir
VintageNetWizard.run_wizard(ssl: [keyfile: "/path/to/key.pem", certfile: "/path/to/cert.pem"])
```

To see all available options see `Plug.SSL.configure/1` and Erlang's `:ssl`
module.

### Backends

Backends control how `VintageNetWizard` configures the network. The default
backend changes the network configuration as you would expect. This can get in
the way of development and can be disabled by using the
`VintageNetWizard.Backend.Mock` backend:

```elixir
config :vintage_net_wizard,
  backend: VintageNetWizard.Backend.Mock
```

## JSON API

It is possible to write a smartphone app to configure your device using an API
endpoint. Documentation for the API is in [json-api.md](json-api.md).

## Running the example

The example builds a Nerves firmware image for supported Nerves devices
 that demonstrates the wizard. The wizard will run on
the first boot and also after a button has been held down for 5 seconds.

For the button to work, you'll need to wire up a button to GPIO 17/pin 11 and
3v3/pin 1 on the Raspberry Pi's GPIO header. See the image below for the
location:

[![Raspberry Pi Pinout from pinout.xyz](assets/pinout-xyz.png)](https://pinout.xyz/#)

If you don't have a button, you can use a jumper wire to temporarily connect 3v3
power to pin 11. If you have a Raspberry Pi hat with a button connected to a
different GPIO pin, you can specify with pin to use in your config:

```elixir
config :vintage_net_wizard, gpio_pin: 27
```

The next step is to build the firmware. Make sure that you've installed Nerves
and run the following:

```sh
cd example

# Set the target to rpi0, rpi3, or rpi4 depending on what you have
export MIX_TARGET=rpi3
mix deps.get
mix firmware

# Insert a MicroSD card or whatever media your board takes
mix burn
```

Place the MicroSD card in the Raspberry Pi and power it on. You should see a
WiFi access point appear with the SSID "nerves-1234" where "1234" are part of
the device's serial number. Connect to the access point and then point your web
browser at [http://wifi.config](http://wifi.config/) or
[http://192.168.0.1/](http://192.168.0.1/). If you've configured an SSL
certificate, it's possible to use `https`. You may also need to change the
`:dns_name` configuration to match the name on your SSL certificate.

The SSID defaults to the hostname of the device, and you can change the SSID via
the `config.exs`:

```elixir
config :vintage_net_wizard,
  ssid: "MY_SSID"
```

## Callbacks when Stopping

There may be cases that your application needs to know when the wizard
is stopped (i.e. start your app once the port is free, etc).

For that, you can use the `:on_exit` options when calling
`VintageNetWizard.run_wizard/1` and specify a `{module, function, args}` tuple of the function to call after the wizard has stopped.

```elixir
defmodule MyApp do
  def start_wizard() do
    VintageNetWizard.run_wizard(
      on_exit: {__MODULE__, :handle_on_exit, []}
    )
  end

  def handle_on_exit() do
    Logger.info("VintageNetWizard stopped")
  end
end
```
