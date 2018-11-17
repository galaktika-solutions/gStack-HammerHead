from django.db import models
from django.conf import settings
from django.core.validators import MaxLengthValidator
from mailer import send_html_mail
from premailer import Premailer
from django.template import loader
from django.utils.translation import ugettext_lazy as _
from django.contrib.auth.models import (
    BaseUserManager, AbstractBaseUser
)
import logging
log = logging.getLogger('django')


class Permission(models.Model):
    name = models.CharField(max_length=30, unique=True)
    description = models.TextField(
        _("Description"), validators=[MaxLengthValidator(255)], blank=True)

    def __str__(self):
        return str(self.name)

    @staticmethod
    def autocomplete_search_fields():
        return ("name__icontains",)


class Group(models.Model):
    name = models.CharField(max_length=30, unique=True)
    permissions = models.ManyToManyField(Permission, through='GroupPermission')

    def __str__(self):
        return self.name


class GroupPermission(models.Model):
    group = models.ForeignKey(Group, on_delete=models.CASCADE)
    permission = models.ForeignKey(Permission, on_delete=models.CASCADE)

    def __str__(self):
        return 'Group: %s Permission: %s' % (
            self.group.name, self.permission.name)


class MyUserManager(BaseUserManager):
    def create_user(self, email, password=None):
        """
        Creates and saves a User with the given email
        """
        if not email:
            raise ValueError('Users must have an email address')

        user = self.model(
            email=self.normalize_email(email),
        )

        user.set_password(password)
        user.save()

        return user

    def create_superuser(self, email, password):
        """
        Creates and saves a superuser with the given email, date of
        birth and password.
        """
        user = self.create_user(
            email,
            password=password,
        )
        user.is_admin = True
        user.save()
        return user


class User(AbstractBaseUser):
    email = models.EmailField(_('Email'), max_length=80, unique=True)
    first_name = models.CharField(_('First Name'), max_length=40, blank=True)
    last_name = models.CharField(_('Last Name'), max_length=80, blank=True)
    is_active = models.BooleanField(_('Is Active'), default=True)
    is_staff = models.BooleanField(_('Is Staff'), default=True)
    is_admin = models.BooleanField(_('Is Admin'), default=False)
    last_login = models.DateTimeField(_('Last Login'), blank=True, null=True),
    objects = MyUserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []

    class Meta:
        ordering = ['email']

    def __str__(self):
        return str(self.full_name)

    @property
    def full_name(self):
        if self.first_name and self.last_name:
            return (self.first_name + ' ' + self.last_name).strip()
        elif self.last_name:
            return self.last_name
        return self.email

    def get_full_name(self):
        return self.first_name + ' ' + self.last_name

    def has_perm(self, perm, obj=None):
        "Does the user have a specific permission?"
        # Simplest possible answer: Yes, always
        return True

    def has_module_perms(self, app_label):
        "Does the user have permissions to view the app `app_label`?"
        # Simplest possible answer: Yes, always
        return True

    @property
    def username(self):
        return self.email

    @property
    def is_superuser(self):
        return self.is_admin

    def save(self):
        old = None
        if self.id is not None:
            old = User.objects.get(pk=self.id)
        super().save()
        if old is None:
            from_email = settings.DEFAULT_FROM_EMAIL
            to_address = settings.ADMIN_EMAIL
            email_subject = 'New user is created'
            email_subject = settings.EMAIL_SUBJECT_PREFIX + email_subject
            content = {
                'text': email_subject,
                'from_email': from_email,
                'subject': email_subject,
                'email': self.email,
            }

            template = 'email_templates/new_user.html'
            body = Premailer(
                loader.render_to_string(template, content)
            ).transform()
            send_html_mail(
                email_subject,
                body,
                body,
                settings.DEFAULT_FROM_EMAIL,
                [to_address],

            )

    @staticmethod
    def autocomplete_search_fields():
        return ("email__icontains",)


class UserPermission(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    permission = models.ForeignKey(Permission, on_delete=models.CASCADE)

    def __str__(self):
        return "#%s User: #%s Permission: #%s" % (
            self.id, self.user.email, self.permission.name)

    def delete(self):
        deleted_id = self.id
        super(UserPermission, self).delete()
        from notification.models import UserSubscription
        try:
            qs = UserSubscription.objects.all()
            qs = qs.get(notification__permission=self.permission,
                        user=self.user)
            perm_ok = self.user.has_perm(
                self.permission.name, ignore_admin=True, skip_u=deleted_id)

            if not perm_ok:
                qs.delete()
                log.info('Subscription deleted!')
        except UserSubscription.DoesNotExist:
            log.info('No Subscription to delete!')


class Membership(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='membership_user'
    )
    group = models.ForeignKey(Group, on_delete=models.CASCADE,)

    class Meta:
        unique_together = ('user', 'group')

    def __str__(self):
        return '%s %s' % (self.user.full_name, self.group.name)

    def delete(self):
        deleted_id = self.id
        super(Membership, self).delete()
        from notification.models import UserSubscription
        for gp in self.group.grouppermission_set.all():
            try:
                qs = UserSubscription.objects.all()
                qs = qs.get(notification__permission=gp.permission,
                            user=self.user)
                perm_ok = self.user.has_perm(
                    gp.permission.name, ignore_admin=True, skip_m=deleted_id)
                if not perm_ok:
                    qs.delete()
                    log.info('Subscription deleted!')
            except UserSubscription.DoesNotExist:
                log.info('No Subscription to delete!')
