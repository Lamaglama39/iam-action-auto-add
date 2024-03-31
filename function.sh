#!/bin/bash

# ログフォーマット
function log_output() {
	local -r log="$1"
	echo "${log}" | awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }'
}

# IAMポリシー 取得処理
# 現在のIAMポリシーをファイル出力
function get_iam_policy() {
	aws iam get-policy-version \
		--policy-arn "${TARGET_IAM_POLICY_ARN}" \
		--version-id "$(aws iam get-policy \
		--policy-arn "${TARGET_IAM_POLICY_ARN}" | jq -r '.Policy.DefaultVersionId')" | jq -r '.PolicyVersion.Document' > policy_document.json

	log_output "GetPolicy : ${TARGET_IAM_POLICY_ARN}"
}

# IAMポリシー 既存権限チェック
# 追加対象の権限がすでに付与されている場合は処理をスキップ
function check_iam_policy() {
  local -r add_action=$1

	if grep -q "${add_action}" "${IAM_POLICY_JSON}" ; then
		log_output "Action is already included in the permission."
		return 1
	fi
}

# IAMポリシー バージョニング処理
# バージョンが5以上であれば、もっとも古いものを削除する
function versioning_iam_policy() {
	local -r version_count=$(aws iam list-policy-versions \
														--policy-arn "${TARGET_IAM_POLICY_ARN}" \
														--query 'Versions[].VersionId' \
														--output text | wc -w)

	if [[ "$version_count" -ge 5 ]]; then
		local -r old_version=$(aws iam list-policy-versions \
														--policy-arn "${TARGET_IAM_POLICY_ARN}" \
														--query 'Versions[].VersionId' \
														--output text | awk '{print $NF}')

		aws iam delete-policy-version \
			--policy-arn "${TARGET_IAM_POLICY_ARN}" \
			--version-id "${old_version}"

		log_output "VersioningPolicy : Success."
	fi
}

# IAMポリシー 更新処理
function update_iam_policy() {
  local -r add_action=$1

	#不足している権限をファイルに追記
	jq --arg add_action "${add_action}" '.Statement[0].Action += [$add_action]' policy_document.json > temp.json && mv temp.json policy_document.json

	#追記したファイルをもとにIAMポリシーを更新する
	aws iam create-policy-version \
		--policy-arn "${TARGET_IAM_POLICY_ARN}" \
		--policy-document file://"${IAM_POLICY_JSON}" \
		--set-as-default \
		> /dev/null

	log_output "UpdatePolicy : Success."
	log_output "Waiting for update for 10 seconds."

	sleep 10
}
