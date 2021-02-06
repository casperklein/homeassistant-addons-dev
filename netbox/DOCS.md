# Netbox for Home Assistant

[Netbox](https://github.com/netbox-community/netbox) is an open source web application designed to help manage and document computer networks. 

## Installation:

1. Add [this](https://github.com/casperklein/homeassistant-addons) Home Assistant add-ons repository to your Home Assistant instance.
1. Install the netbox add-on.
1. Set *user* and *password* in the add-on options.
    * This will add a new superuser to netbox after the add-on starts.
    * The credentials can be safely removed from the add-on options afterwards.
1. Start the add-on.
1. Click on the "OPEN WEB UI" button to open Netbox.

## Configuration:

**Note**: _Remember to restart the add-on when the configuration is changed._

Example add-on configuration:

    "user": "admin"
    "password": "insecure"
    "https": true
    "certfile": "fullchain.pem"
    "keyfile": "privatekey.pem"

**Note**: _This is just an example, don't copy and paste it! Create your own!_

### Option: `user` / `password`

If set, a new netbox superuser is created on add-on start.

**Note**: Use this options only once. Don't forget to remove the credentials afterwards.

### Option: `https`

Enables/Disables HTTPS on the web interface. Set it `true` to enable it, `false` otherwise.

### Option: `certfile`

A file containing a certificate, including its chain. If this file doesn't exist, the add-on start will fail.

**Note**: The file MUST be stored in the Home Assistant `/ssl` directory, which is the default for Home Assistant.

### Option: `keyfile`

A file containing the private key. If this file doesn't exist, the add-on start will fail.

**Note**: The file MUST be stored in the Home Assistant `/ssl` directory, which is the default for Home Assistant.
