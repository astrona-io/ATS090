# Section 120: OAuth 2.0 Device Authorization Grant

A smart TV or a command-line tool has no good way to type a password. The device authorization grant lets the user finish the sign-in on a second device that has a browser.

This section covers the flow, the client settings, the polling requests and errors, and the risks of the flow. You check each setting by requesting a device code and reading the answer.

**Topic covered:** the device authorization grant

## What you will learn

- How the device code, the user code and the verification address work together.
- How to enable the grant and set the code lifetime and the polling interval.
- How a device should react to each polling error.
- How to limit device code phishing and other risks.

## The learning path

The section has one module. It has a landing page, 4 short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. OAuth 2.0 Device Authorization Grant

The playground holds the namespace `device-demo` with Keycloak, the realm `inventory`, the user `alice` and the public client `kiosk` with the device grant on. You request device codes with `curl` and change the client with `kcadm.sh`.

1. How The Device Flow Works
2. Enabling The Grant On A Client, followed by the lab **Enable The Device Grant**
3. Polling, Errors And Timing
4. Security Of The Device Flow
5. Summary

## Section capstone: Secure A TV App Login

The capstone is one graded scenario that brings the module together. A TV client is confidential, its codes live an hour, it can poll every second and it allows the password grant. Make it safe and keep the device grant working. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-120/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-120/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-090-capstone-120
```
