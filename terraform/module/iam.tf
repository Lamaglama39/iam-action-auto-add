
# IAMユーザー
resource "aws_iam_user" "user" {
  name   = "${var.project}-user"
  path = "/"

  tags = {
    tag-key = "${var.project}-user"
  }
}

# アクセスキー
resource "aws_iam_access_key" "key" {
  user = aws_iam_user.user.name
}

# IAMポリシードキュメント IAMアクション
data "aws_iam_policy_document" "iam_action" {
  statement {
    effect = "Allow"
    actions = [
      "iam:GetPolicyVersion",
      "iam:GetPolicy",
      "iam:CreatePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:DeletePolicyVersion",
    ]
    resources = ["*"]
  }
}

# IAMポリシー IAMアクション
resource "aws_iam_policy" "policy" {
  name   = "${var.project}-iam-policy"
  policy = data.aws_iam_policy_document.iam_action.json
}

# アタッチ  IAMアクション
resource "aws_iam_user_policy_attachment" "attachment" {
  user   = aws_iam_user.user.name
  policy_arn  = aws_iam_policy.policy.arn
}

# IAMポリシー 権限付与シェル用
resource "aws_iam_policy" "add_policy" {
  name   = "${var.project}-add-policy"
  policy = data.aws_iam_policy_document.iam_action.json
}

# アタッチ  権限付与シェル用
resource "aws_iam_user_policy_attachment" "add_attachment" {
  user   = aws_iam_user.user.name
  policy_arn  = aws_iam_policy.add_policy.arn
}
