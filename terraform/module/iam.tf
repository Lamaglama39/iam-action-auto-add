
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

# IAMポリシードキュメント IAMアクション用
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

# IAMポリシー IAMアクション用
resource "aws_iam_policy" "policy" {
  name   = "${var.project}-iam-policy"
  policy = data.aws_iam_policy_document.iam_action.json
}

# IMAポリシーアタッチ  IAMアクション用
resource "aws_iam_user_policy_attachment" "attachment" {
  user   = aws_iam_user.user.name
  policy_arn  = aws_iam_policy.policy.arn
}

# IAMポリシー 権限付与シェル用
resource "aws_iam_policy" "target_policy" {
  name   = "${var.project}-target-policy"
  policy = data.aws_iam_policy_document.iam_action.json
}

# アタッチ  権限付与シェル用
resource "aws_iam_user_policy_attachment" "target_attachment" {
  user   = aws_iam_user.user.name
  policy_arn  = aws_iam_policy.target_policy.arn
}
