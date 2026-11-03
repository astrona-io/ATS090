# Solution: Correct The Permissions Of A Report API

Work the task yourself first. Running `astrona submit -c sections/section-100/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the policies and permissions

```sh
NAMESPACE=authz-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
RS_ID=$(kcadm get clients -r inventory -q clientId=invoice-api --fields id --format csv --noquotes | tr -d '\r')
kcadm get "clients/$RS_ID/authz/resource-server/policy" -r inventory --fields id,name,type,logic
kcadm get "clients/$RS_ID/authz/resource-server/permission" -r inventory --fields id,name,type
```

The policy `finance-policy` has the logic `NEGATIVE`. It passes users who do **not** have the role, so `bob` reads and `alice` does not. The permission `report-delete` uses `finance-policy` and not `admin-policy`.

## Step 2: Make the finance policy positive

```sh
FIN_POL=$(kcadm get "clients/$RS_ID/authz/resource-server/policy" -r inventory -q name=finance-policy --fields id --format csv --noquotes | tr -d '\r')
FIN_ROLE=$(kcadm get roles/finance -r inventory --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$RS_ID/authz/resource-server/policy/role/$FIN_POL" -r inventory \
  -b "{\"id\":\"$FIN_POL\",\"name\":\"finance-policy\",\"type\":\"role\",\"logic\":\"POSITIVE\",\"decisionStrategy\":\"UNANIMOUS\",\"roles\":[{\"id\":\"$FIN_ROLE\",\"required\":false}]}"
```

## Step 3: Point the delete permission at the admin policy

```sh
ADM_POL=$(kcadm get "clients/$RS_ID/authz/resource-server/policy" -r inventory -q name=admin-policy --fields id --format csv --noquotes | tr -d '\r')
PERM_ID=$(kcadm get "clients/$RS_ID/authz/resource-server/permission" -r inventory -q name=report-delete --fields id --format csv --noquotes | tr -d '\r')
RES_ID=$(kcadm get "clients/$RS_ID/authz/resource-server/resource" -r inventory -q name=report --fields _id --format csv --noquotes | tr -d '\r')
DELETE_ID=$(kcadm get "clients/$RS_ID/authz/resource-server/scope" -r inventory -q name=delete --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$RS_ID/authz/resource-server/permission/scope/$PERM_ID" -r inventory \
  -b "{\"id\":\"$PERM_ID\",\"name\":\"report-delete\",\"type\":\"scope\",\"logic\":\"POSITIVE\",\"decisionStrategy\":\"UNANIMOUS\",\"resources\":[\"$RES_ID\"],\"scopes\":[\"$DELETE_ID\"],\"policies\":[\"$ADM_POL\"]}"
```

## Step 4: Request the decisions again

Use the `decision` function from the module with `alice`, `bob` and `carol` and both permissions. The expected answers are read and not delete for `alice`, both for `carol`, neither for `bob`. Run `astrona submit` to grade the capstone.
