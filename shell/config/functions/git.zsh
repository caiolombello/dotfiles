# Git push with GPG verification
push() {
  echo "teste" | gpg --clearsign > /dev/null || {
    echo "Falha ao assinar. Abortando." >&2
    return 1
  }

  gt -C || return 1
  gp "$@"
}
