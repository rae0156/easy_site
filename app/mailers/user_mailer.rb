# encoding: UTF-8
class UserMailer < ActionMailer::Base
   
  WEB_SITE_NAME  = EsSetup.get_setup("site_web")   
   
    def password_reset_instructions(user,newpassword)
      tmp_subject = WEB_SITE_NAME + " : " + "Instructions pour la réinitialisation de votre mot de passe".trn
      @name = user.firstname + ' ' + user.name
      @newpassword = newpassword
      @web_site_name = WEB_SITE_NAME
      mail( :subject => tmp_subject,
            :from => "no-reply@" + WEB_SITE_NAME,
            :to => user.mail,
            :date => Time.now
           ) 
      #Message.create_mail("no-reply@" + WEB_SITE_NAME, user.mail,tmp_subject,"Mail automatique envoyé le #{Time.zone.now.to_s[0..18]}")      
    end

    def new_psw_user(user)
      tmp_subject = WEB_SITE_NAME + " : " + "Changement de mot de passe".trn
      @name = user.firstname + ' ' + user.name
      @user = user.mail
      @password = user.tempo_password
      @web_site_name = WEB_SITE_NAME
      mail( :subject => tmp_subject,
            :from => "no-reply@" + WEB_SITE_NAME,
            :to => user.mail,
            :date => Time.now
           ) 
      #Message.create_mail("no-reply@" + WEB_SITE_NAME, user.mail,tmp_subject,"Mail automatique envoyé le #{Time.zone.now.to_s[0..18]}")
    end

    def confirm_new_user(user)
      tmp_subject = WEB_SITE_NAME + " : " + "Confirmation de votre inscription".trn
      @name = user.firstname + ' ' + user.name
      @user = user.mail
      @password = user.tempo_password
      @web_site_name = WEB_SITE_NAME
      mail( :subject => tmp_subject,
            :from => "no-reply@" + WEB_SITE_NAME,
            :to => user.mail,
            :date => Time.now
           ) 
      #Message.create_mail("no-reply@" + WEB_SITE_NAME, user.mail,tmp_subject,"Mail automatique envoyé le #{Time.zone.now.to_s[0..18]}")
    end

    def validation_new_user(user,adrweb)
      tmp_subject = WEB_SITE_NAME + " : " + "Instructions pour la validation de inscription".trn
      @name = user.firstname + ' ' + user.name
      @confirm_new_user = adrweb + "/es_users/confirm/" + user.active
      @web_site_name = WEB_SITE_NAME
      mail( :subject => tmp_subject,
            :from => "no-reply@" + WEB_SITE_NAME,
            :to => user.mail,
            :date => Time.now
           ) 
      #Message.create_mail("no-reply@" + WEB_SITE_NAME, user.mail,tmp_subject,"Mail automatique envoyé le #{Time.zone.now.to_s[0..18]}")
    end

    def activation_new_mail(user,to)
      tmp_subject = WEB_SITE_NAME + " : " + "Confirmation de votre activation de mail".trn
      @name = user.firstname + ' ' + user.name
      @old_mail = user.mail
      @new_mail = user.newmail
      @web_site_name = WEB_SITE_NAME
      mail( :subject => tmp_subject,
            :from => "no-reply@" + WEB_SITE_NAME,
            :to => user[to],
            :date => Time.now
           ) 
    end

    def mail_change_instructions(user,adrweb='')
      tmp_subject = adrweb.blank? ? (WEB_SITE_NAME + " : " + "Changement d'adresse mail".trn) : (WEB_SITE_NAME + " : " + "Instructions pour le changement d'adresse mail".trn)
      @name = user.firstname + ' ' + user.name
      @new_mail = user.newmail
      @confirm_new_mail = adrweb.blank? ? '' : adrweb + "/es_users/confirm_mail/" + user.activemail
      @web_site_name = WEB_SITE_NAME
      mail( :subject => tmp_subject,
            :from => "no-reply@" + WEB_SITE_NAME,
            :to => user.mail,
            :date => Time.now
           ) 
      #Message.create_mail("no-reply@" + WEB_SITE_NAME, user.mail,tmp_subject,"Mail automatique envoyé le #{Time.zone.now.to_s[0..18]}")
    end

    def activation_user(user,password)
      tmp_subject = WEB_SITE_NAME + " : " + "Activation de votre utilisateur".trn
      @name = user.firstname + ' ' + user.name
      @mail = user.mail
      @web_site_name = WEB_SITE_NAME
      @newpassword = password
      mail( :subject => tmp_subject,
            :from => "no-reply@" + WEB_SITE_NAME,
            :to => user.mail,
            :date => Time.now
           ) 
      #Message.create_mail("no-reply@" + WEB_SITE_NAME, user.mail,tmp_subject,"Mail automatique envoyé le #{Time.zone.now.to_s[0..18]}")
    end


    def send_message(user_from,user_to,sujet,message)
      @message = message
      @web_site_name = WEB_SITE_NAME
      mail( :subject => sujet,
            :from => user_from,
            :to => user_to,
            :date => Time.now
           ) 
      #Message.create_mail(user_from, user_to,sujet,message)
    end
  end
    