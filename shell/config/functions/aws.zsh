# AWS EC2 functions
ec2list() {
  aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].[InstanceId, Tags[?Key=='Name'].Value | [0], PrivateIpAddress, PublicIpAddress]" \
    --output text
}

ec2ssh() {
  local name="$1"

  if [[ -z "$name" ]]; then
    echo "Uso: ec2ssh <nome-da-maquina>"
    return 1
  fi

  local ip
  ip=$(aws --no-cli-pager ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=$name" \
    --query "Reservations[*].Instances[*].PublicIpAddress" \
    --output text)

  if [[ -z "$ip" ]]; then
    echo "Instância '$name' não encontrada ou sem IP público."
    return 1
  fi

  echo "Conectando em $name ($ip)..."
  ssh ubuntu@"$ip"
}
