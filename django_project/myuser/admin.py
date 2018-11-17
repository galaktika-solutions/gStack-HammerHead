# coding: utf-8
# Django core and 3rd party imports
from django import forms
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.translation import ugettext_lazy as _

from .models import (
    User, Group, Permission, Membership, GroupPermission, UserPermission
)


class UserCreationForm(forms.ModelForm):
    """
    A form for creating new users. Includes all the required fields, plus a
    repeated password.
    """
    password1 = forms.CharField(
        label=_('Password'), widget=forms.PasswordInput)
    password2 = forms.CharField(
        label=_('Password confirmation'), widget=forms.PasswordInput)

    class Meta:
        model = User
        fields = (
            'password1', 'password2', 'email', 'first_name', 'last_name',
            'is_active', 'is_staff', 'is_admin')

    def clean_password2(self):
        """ Check that the two password entries match """
        password1 = self.cleaned_data.get("password1")
        password2 = self.cleaned_data.get("password2")
        if password1 and password2 and password1 != password2:
            raise forms.ValidationError(_("Passwords don't match!"))
        return password2

    def save(self, commit=True):
        """ Save the provided password in hashed format """
        user = super(UserCreationForm, self).save(commit=False)
        user.set_password(self.cleaned_data["password1"])
        if commit:
            user.save()
        return user


class UserPermissionInline(admin.TabularInline):
    model = UserPermission
    extra = 0
    raw_id_fields = ('permission', )
    autocomplete_lookup_fields = {'fk': raw_id_fields}


class MembershipInline(admin.TabularInline):
    model = Membership
    extra = 0


class MyUserAdmin(UserAdmin):
    """ The forms to add and change user instances """
    add_form = UserCreationForm

    list_display = ('id', 'email', 'is_active', 'is_staff', 'is_admin')
    list_display_links = list_display
    list_filter = ('is_admin', 'is_staff', 'is_active')
    readonly_fields = ['last_login', ]
    fieldsets = (
        ('Personal info',
            {'fields': ('email', 'first_name', 'last_name', 'password',)}),
        ('Permissions',
            {'fields': ('is_active', 'is_staff', 'is_admin', )}),
    )

    add_fieldsets = (
        ('Personal info',
            {'fields': ('email', 'password1', 'password2', 'first_name',
                        'last_name')}),
        ('Permissions',
            {'fields': ('is_active', 'is_staff', 'is_admin',)}),
    )
    search_fields = ('email',)
    ordering = ('email',)
    filter_horizontal = ()
    inlines = [MembershipInline, UserPermissionInline]


admin.site.register(User, MyUserAdmin)


class GroupPermissionInline(admin.TabularInline):
    model = GroupPermission
    extra = 0
    raw_id_fields = ('permission',)
    autocomplete_lookup_fields = {'fk': raw_id_fields}

    def get_queryset(self, request):
        queryset = super(GroupPermissionInline, self).get_queryset(request)
        return queryset.select_related()


class GroupAdmin(admin.ModelAdmin):
    list_display = ('id', 'name')
    list_display_links = list_display
    search_fields = ['name', ]
    list_per_page = 20
    model = Group
    inlines = [GroupPermissionInline, ]


admin.site.register(Group, GroupAdmin)


class PermissionAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'description')
    list_display_links = list_display
    search_fields = ['name', ]
    list_per_page = 20
    model = Permission


admin.site.register(Permission, PermissionAdmin)


class MembershipAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'group')
    list_display_links = list_display
    list_per_page = 20
    list_filter = ('group', 'user')
    raw_id_fields = ('user', )
    autocomplete_lookup_fields = {
        'fk': raw_id_fields,
    }
    model = Membership


admin.site.register(Membership, MembershipAdmin)
