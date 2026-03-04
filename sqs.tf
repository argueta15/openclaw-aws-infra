# sqs.tf

resource "aws_sqs_queue" "openclaw_jobs" {
  name                      = "openclaw-jobs-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400 # 1 día, los jobs expiran si nadie los atiende
  receive_wait_time_seconds = 20    # Long polling activo
}

# (Opcional) Dead Letter Queue para jobs fallidos
resource "aws_sqs_queue" "openclaw_jobs_dlq" {
  name = "openclaw-jobs-dlq"
}

resource "aws_sqs_queue_redrive_policy" "openclaw_jobs_dlq_policy" {
  queue_url = aws_sqs_queue.openclaw_jobs.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.openclaw_jobs_dlq.arn
    maxReceiveCount     = 3
  })
}
