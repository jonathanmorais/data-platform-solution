# ml-platform-solution

## Set your environments variables

`export ACCESS_KEY="<key>`
`export ACCESS_SECRET_KEY="<secret_key>`
`export TF_VAR_access_key="<key>`
`export TF_VAR_access_secret_key=="<secret_key>`

## Package your lambdas

`make lambda_processor`
`make lambda_client`

## Deploy infra
`make deploy`

## Destruct infra

`make destroy`
## Architecture
![arch](https://user-images.githubusercontent.com/12867382/163460891-afd91213-a1cb-4b3f-8ce3-ef25b311b4cb.png)
