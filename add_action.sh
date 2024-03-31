#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${0}")";pwd)"

#変数設定
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/function.sh"

#実行対象 コマンドリスト
export COMMAND_LIST="${SCRIPT_DIR}/command.txt"
export IAM_POLICY_JSON="${SCRIPT_DIR}/policy_document.json"

#実行結果 ログfile
declare OUTPUT_FILE
OUTPUT_FILE="${SCRIPT_DIR}/output_log_$(date +"%Y%m%d%H%M").txt"
export OUTPUT_FILE

#ログファイル出力設定
exec > >(tee -a "${OUTPUT_FILE}") 2>&1

# main処理
function main() {
	while read -r command; do
		while true; do

			#コマンド実行
      log_output "RunCommand : ${command}"
			if ! response=$(eval "${command}" --output text 2>&1 | sed -z 's/\n//g'); then

        #権限不足エラーが発生した場合、エラーメッセージを出力
				log_output "ErrorMessage : ${response}"

				#不足権限 取得
				target_action=$(printf "%s" "$response" | awk -F"perform: " '{print $2}' | awk '{print $1}' | sed -z 's/\n//g')

				#該当のアクションが存在するか確認
				if [[ -z "${target_action}" ]]; then
					log_output "Targetaction is empty."
					break
				elif grep -q "${target_action}" "data/iam_actions.txt"; then
					log_output "AddTargetAction : ${target_action}"
				else
					log_output "Unknown Action : ${target_action}"
					break
				fi

				# IAMポリシー取得
				get_iam_policy

				# IAMポリシーチェック処理
        if ! check_iam_policy "${target_action}"; then
          break
        fi

				# IAMポリシー バージョニング処理
				versioning_iam_policy

				# IAMポリシー 更新処理
				update_iam_policy "${target_action}"

			else
				##コマンドが成功した場合
				log_output "CommandExec : Success."
				break
			fi
		done
	done < "${COMMAND_LIST}"
}

main
