require "sidekiq/web"

# O painel do Sidekiq expõe todo job enfileirado — seus argumentos, seu
# histórico de retentativa — e os botões para matar ou repetir cada um. Fora de
# desenvolvimento ele fica atrás de HTTP Basic.
#
# Credencial ausente NEGA o acesso em vez de liberá-lo: variável esquecida no
# deploy não pode reabrir a porta silenciosamente.
unless Rails.env.development? || Rails.env.test?
  Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
    expected_user     = ENV["SIDEKIQ_WEB_USER"].to_s
    expected_password = ENV["SIDEKIQ_WEB_PASSWORD"].to_s

    next false if expected_user.empty? || expected_password.empty?

    # & e não &&: as duas comparações sempre rodam, para não vazar por tempo
    # qual das duas falhou.
    ActiveSupport::SecurityUtils.secure_compare(user, expected_user) &
      ActiveSupport::SecurityUtils.secure_compare(password, expected_password)
  end
end
