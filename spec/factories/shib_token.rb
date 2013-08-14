# -*- coding: utf-8 -*-
Factory.define :shib_token do |s|
  s.association :user, :factory => :user
  s.data {
    hash = {}
    hash["Shib-Application-ID"] = "default"
    hash["Shib-Session-ID"] = "09a612f952cds995e4a86ddd87fd9f2a"
    hash["Shib-Identity-Provider"] = "https://login.somewhere/idp/shibboleth"
    hash["Shib-Authentication-Instant"] = "2011-09-21T19:11:58.039Z"
    hash["Shib-Authentication-Method"] = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
    hash["Shib-AuthnContext-Class"] = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
    hash["Shib-brEduPerson-brEduAffiliationType"] = "student;position;faculty"
    hash["Shib-eduPerson-eduPersonPrincipalName"] = "75a988943825d2871e1cfa75473ec0@ufrgs.br"
    hash["Shib-inetOrgPerson-cn"] = "Rick Astley"
    hash["Shib-inetOrgPerson-sn"] = "Rick Astley"
    hash["Shib-inetOrgPerson-mail"] = "nevergonnagiveyouup@rick.com"
    hash["cn"] = "Rick Astley"
    hash["mail"] = "nevergonnagiveyouup@rick.com"
    hash["uid"] = "00000000000"
    hash["ufrgsVinculo"] = "ativo:12:Funcionário de Fundações da UFRGS:1:Instituto de Informática:NULL:NULL:NULL:NULL:01/01/2011:NULL;inativo:6:Aluno de mestrado acadêmico:NULL:NULL:NULL:NULL:2:COMPUTAÇÃO:01/01/2001:11/12/2002"
    hash.to_yaml
  }
  s.after_build do |obj|
    obj.identifier = obj.user.email
  end
end
