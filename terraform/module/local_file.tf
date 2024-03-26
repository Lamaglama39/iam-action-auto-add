# 変数用ファイル出力
resource "local_file" "env" {
  content = templatefile("./module/conf/env.tpl", {
    AWS_ACCESS_KEY_ID     = "${aws_iam_access_key.key.id}"
    AWS_SECRET_ACCESS_KEY = "${aws_iam_access_key.key.secret}"
    TARGET_IAM_POLICY_ARN = "${aws_iam_policy.target_policy.arn}"
  })
  filename = "../env.sh"
}

# コマンドリスト サンプルファイル出力
resource "local_file" "cmd" {
  content = templatefile("./module/conf/command.tpl", {
  })
  filename = "../command.txt"
}
