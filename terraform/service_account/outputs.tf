output "terraform_sa_id" {
  value = yandex_iam_service_account.terraform.id
}

output "terraform_sa_key_id" {
  value = yandex_iam_service_account_key.terraform_key.id
}

output "terraform_sa_key_created_at" {
  value = yandex_iam_service_account_key.terraform_key.created_at
}

output "terraform_sa_key_pem" {
  value     = yandex_iam_service_account_key.terraform_key.private_key
  sensitive = true
}

output "tf_s3_access_key" {
  value     = yandex_iam_service_account_static_access_key.tf_sa_key.access_key
  sensitive = true
}

output "tf_s3_secret_key" {
  value     = yandex_iam_service_account_static_access_key.tf_sa_key.secret_key
  sensitive = true
}

# terraform output -raw tf_s3_secret_key
# terraform output -raw tf_s3_access_key

#terraform output -raw terraform_sa_key_pem > sa.pem

# jq -n \
#   --arg id "$(terraform output -raw terraform_sa_key_id)" \
#   --arg sa_id "$(terraform output -raw terraform_sa_id)" \
#   --arg created_at "$(terraform output -raw terraform_sa_key_created_at)" \
#   --arg key "$(terraform output -raw terraform_sa_key_pem)" \
#   '{
#     id: $id,
#     service_account_id: $sa_id,
#     created_at: $created_at,
#     key_algorithm: "RSA_2048",
#     private_key: $key
#   }' > terraform-key.json
