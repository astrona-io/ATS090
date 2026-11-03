# Administering Sessions

Applications end sessions through logout. An operator needs more: see who is signed in, cut off one account, clear everything after an incident, and shorten limits. This part uses the admin API and the realm settings.

## See sessions

Sessions can be listed for a user, for a client, or counted for the realm. Define the helpers and sign in twice to create two sessions:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=logout-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
get_tokens() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid
}
get_tokens > /dev/null
get_tokens > /dev/null
USER_ID=$(kcadm get users -r inventory -q username=alice --fields id --format csv --noquotes | tr -d '\r')
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm get "users/$USER_ID/sessions" -r inventory --fields id,ipAddress,start
kcadm get "clients/$CLI_ID/session-count" -r inventory
```

The first call lists the two sessions of `alice`. The second returns the number of sessions of the client. Each sign-in with the password grant starts its own session.

## End one session

Use the session ID from the list. `DELETE` on the realm's session path removes one session and leaves the others:

```sh
SESSION_ID=$(kcadm get "users/$USER_ID/sessions" -r inventory --fields id --format csv --noquotes | tr -d '\r' | head -1)
kcadm delete "sessions/$SESSION_ID" -r inventory
kcadm get "users/$USER_ID/sessions" -r inventory --fields id
```

One session is left.

## End everything for a user, or for the realm

`POST users/<id>/logout` removes all sessions of one user. `POST logout-all` removes all sessions of the realm, which is the reaction to a leaked signing key or a mass compromise:

```sh
kcadm create "users/$USER_ID/logout" -r inventory -b '{}'
kcadm create logout-all -r inventory -b '{}'
```

Both also send back-channel logout messages to clients that have a back-channel URL. Disabling a user (`enabled=false`) removes the user's sessions too, and it blocks new sign-ins, which a plain logout does not.

## Set the limits

The realm limits decide how long sessions live without anyone acting:

```sh
kcadm update realms/inventory -s ssoSessionIdleTimeout=900 -s ssoSessionMaxLifespan=28800
kcadm get realms/inventory --fields ssoSessionIdleTimeout,ssoSessionMaxLifespan
```

The idle limit is now 15 minutes and the max limit eight hours. Existing sessions keep being checked against the new values on their next use.

## Which tool for which event

| Event | Action |
| --- | --- |
| A user reports a lost phone | End the user's sessions, then reset the credentials |
| One suspicious session | Delete that session by its ID |
| A leaked realm key | Rotate the key, then `logout-all` |
| Policy change | Shorten idle and max limits |

You have the full picture: sessions end by logout, by time and by an administrator, applications are told through back-channel or front-channel logout, and issued access tokens run out on their own.

## Your mission: Sign Out A User Everywhere Lab

The mission starts from a realm where `alice` is signed in twice and the idle limit is a full day. You end her sessions with the admin API and set a shorter idle limit.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-090-playground-070-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-070/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-070/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-090-lab-070-01
astrona start ats-090-playground-070-01
```

## Common pitfalls

> [!WARNING]
> - **Running `logout-all` when one user needs it.** It signs out the whole realm.
> - **Ending sessions and not resetting credentials.** The attacker can sign in again.
> - **Shortening the idle limit and expecting access tokens to die.** Access tokens follow their own lifespan.
