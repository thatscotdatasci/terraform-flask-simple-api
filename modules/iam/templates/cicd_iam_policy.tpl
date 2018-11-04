{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:${region}:*:log-group:/aws/codebuild/${codebuild_project_name}",
                "arn:aws:logs:${region}:*:log-group:/aws/codebuild/${codebuild_project_name}:*:*"
            ],
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "*"
            ],
            "Action": [
                "logs:CreateLogGroup"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:ecr:${region}:*:repository/${ecr_repo}"
            ],
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:CompleteLayerUpload",
                "ecr:InitiateLayerUpload",
                "ecr:PutImage",
                "ecr:UploadLayerPart"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "*"
            ],
            "Action": [
                "ecr:GetAuthorizationToken"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:codebuild:${region}:*:project/${codebuild_project_name}"
            ],
            "Action": [
                "codebuild:StartBuild",
                "codebuild:BatchGetBuilds"
            ]
        }
    ]
}
