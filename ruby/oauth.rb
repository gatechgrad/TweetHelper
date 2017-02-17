require 'signet/oauth_1/client'

client = Signet::OAuth1::Client.new(
  :temporary_credential_uri =>
    'https://www.google.com/accounts/OAuthGetRequestToken',
  :authorization_uri =>
    'https://www.google.com/accounts/OAuthAuthorizeToken',
  :token_credential_uri =>
    'https://www.google.com/accounts/OAuthGetAccessToken',
  :client_credential_key => 'gitcommand',
  :client_credential_secret => '!42shiroitokiniro'
)

client.fetch_temporary_credential!(:additional_parameters => {
  :scope => 'https://mail.google.com/mail/feed/atom'
})

=begin
# Send the user to client.authorization_uri, obtain verifier
client.fetch_token_credential!(:verifier => '12345')
response = client.fetch_protected_resource(
  :uri => 'https://mail.google.com/mail/feed/atom'
)
=end
