# encoding: UTF-8
class UserMailer < ActionMailer::Base
      
   
    def password_reset_instructions(user,newpassword)
      web_site_name  = EsSetup.get_setup("site_web")
      tmp_subject = web_site_name + " : " + "Instructions pour la réinitialisation de votre mot de passe".trn
      @name = user.firstname + ' ' + user.name
      @newpassword = newpassword
      @web_site_name = web_site_name
      mail( :subject => tmp_subject,
            :from => "no-reply@" + web_site_name,
            :to => user.mail,
            :date => Time.now
           ) 
      #Message.create_mail("no-reply@" + web_site_name, user.mail,tmp_subject,"Mail automatique envoyé le #{Time.zone.now.to_s[0..18]}")      
    end

    def new_psw_user(user)
      web_site_name  = EsSetup.get_setup("site_web")
      tmp_subject = web_site_name + " : " + "Changement de mot de passe".trn
      @name = user.firstname + ' ' + user.name
      @user = user.mail
      @password = user.tempo_password
      @web_site_name = web_site_name
      mail( :subject => tmp_subject,
            :from => "no-reply@" + web_site_name,
            :to => user.mail,
            :date => Time.now
           ) 
      #Message.create_mail("no-reply@" + web_site_name, user.mail,tmp_subject,"Mail automatique envoyé le #{Time.zone.now.to_s[0..18]}")
    end

    def confirm_new_user(user)
      web_site_name  = EsSetup.get_setup("site_web")
      tmp_subject = web_site_name + " : " + "Confirmation de votre inscription".trn
      @name = user.firstname + ' ' + user.name
      @user = user.mail
      @password = user.tempo_password
      @web_site_name = web_site_name
      mail( :subject => tmp_subject,
            :from => "no-reply@" + web_site_name,
            :to => user.mail,
            :date => Time.now
           ) 
      #Message.create_mail("no-reply@" + web_site_name, user.mail,tmp_subject,"Mail automatique envoyé le #{Time.zone.now.to_s[0..18]}")
    end

    def validation_new_user(user,adrweb)
      web_site_name  = EsSetup.get_setup("site_web")
      tmp_subject = web_site_name + " : " + "Instructions pour la validation de inscription".trn
      @name = user.firstname + ' ' + user.name
      @confirm_new_user = adrweb + "/es_users/confirm/" + user.active
      @web_site_name = web_site_name
      mail( :subject => tmp_subject,
            :from => "no-reply@" + web_site_name,
            :to => user.mail,
            :date => Time.now
           ) 
      #Message.create_mail("no-reply@" + web_site_name, user.mail,tmp_subject,"Mail automatique envoyé le #{Time.zone.now.to_s[0..18]}")
    end

    def activation_new_mail(user,to)
      web_site_name  = EsSetup.get_setup("site_web")
      tmp_subject = web_site_name + " : " + "Confirmation de votre activation de mail".trn
      @name = user.firstname + ' ' + user.name
      @old_mail = user.mail
      @new_mail = user.newmail
      @web_site_name = web_site_name
      mail( :subject => tmp_subject,
            :from => "no-reply@" + web_site_name,
            :to => user[to],
            :date => Time.now
           ) 
    end

    def mail_change_instructions(user,adrweb='')
      web_site_name  = EsSetup.get_setup("site_web")
      tmp_subject = adrweb.blank? ? (web_site_name + " : " + "Changement d'adresse mail".trn) : (web_site_name + " : " + "Instructions pour le changement d'adresse mail".trn)
      @name = user.firstname + ' ' + user.name
      @new_mail = user.newmail
      @confirm_new_mail = adrweb.blank? ? '' : adrweb + "/es_users/confirm_mail/" + user.activemail
      @web_site_name = web_site_name
      mail( :subject => tmp_subject,
            :from => "no-reply@" + web_site_name,
            :to => user.mail,
            :date => Time.now
           ) 
      #Message.create_mail("no-reply@" + web_site_name, user.mail,tmp_subject,"Mail automatique envoyé le #{Time.zone.now.to_s[0..18]}")
    end

    def activation_user(user,password)
      web_site_name  = EsSetup.get_setup("site_web")
      tmp_subject = web_site_name + " : " + "Activation de votre utilisateur".trn
      @name = user.firstname + ' ' + user.name
      @mail = user.mail
      @web_site_name = web_site_name
      @newpassword = password
      mail( :subject => tmp_subject,
            :from => "no-reply@" + web_site_name,
            :to => user.mail,
            :date => Time.now
           ) 
      #Message.create_mail("no-reply@" + web_site_name, user.mail,tmp_subject,"Mail automatique envoyé le #{Time.zone.now.to_s[0..18]}")
    end


    def send_message(user_from,user_to,sujet="Mail de test".trn,message="Ceci est un mail de test".trn)
      web_site_name  = EsSetup.get_setup("site_web")
      @message = message
      @web_site_name = web_site_name
      mail( :subject => sujet,
            :from => user_from,
            :to => user_to,
            :date => Time.now
           ) 
      #Message.create_mail(user_from, user_to,sujet,message)
    end
  end
    