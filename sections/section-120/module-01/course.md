# OAuth 2.0 Device Authorization Grant

A smart TV, a printer or a command-line tool has no good way to type a password. A browser may not exist at all. The **device authorization grant** solves this: the device shows a short code, and the user finishes the sign-in on another device that has a browser, such as a phone.

Keep one sentence in mind: **the device asks for a code pair, the user approves the user code on a second device, and the device polls the token endpoint until the approval arrives.** The device never sees the password.

The module has four parts. **How The Device Flow Works** follows the steps and the messages. **Enabling The Grant On A Client** covers the client settings. **Polling, Errors And Timing** covers the token requests and the error codes. **Security Of The Device Flow** covers lifetimes, intervals and phishing. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Describe the steps and the messages of the device authorization grant.
- Enable the grant on a client and set the code lifetime and the polling interval.
- Request a device code and read the response.
- Name the polling errors and what the device must do for each.
- Say which risks the device flow adds and how to limit them.

## Before you start

You need Kubernetes basics and `curl` and `jq`, and you should know what a public client and an access token are.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`device-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every request is sent from here |

Inside Keycloak, the realm `inventory` holds the user `alice` with the password `alice-password`, and the public client `kiosk` for a display in a shop. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
