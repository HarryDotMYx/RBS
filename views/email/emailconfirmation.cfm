<cfoutput>
<cfset confirmTokenValue = user.emailConfirmationToken & "">
#includePartial("/common/email/header")#
 <h4 style="Margin-top: 0;color: ##565656;font-weight: 700;font-size: 24px;Margin-bottom: 18px;font-family: sans-serif;line-height: 24px">Confirm Your Registration:</h4>
<p style="Margin-top: 0;color: ##565656;font-family: sans-serif;font-size: 16px;line-height: 25px;Margin-bottom: 24px">Hi #user.firstname#,</p>
<p style="Margin-top: 0;color: ##565656;font-family: sans-serif;font-size: 16px;line-height: 25px;Margin-bottom: 24px">Thank you for registering. You need to verify your email address to complete your registration.</p>
<p style="Margin-top: 0;color: ##565656;font-family: sans-serif;font-size: 16px;line-height: 25px;Margin-bottom: 24px">Click the link below to confirm your account:</p>
<p style="Margin-top: 0;color: ##565656;font-family: sans-serif;font-size: 16px;line-height: 25px;Margin-bottom: 24px">#linkto(route="confirmEmail", onlyPath=false, key=confirmTokenValue, host="intranet.sedco.com.my:8888", protocol="https")#</p>
<p style="Margin-top: 0;color: ##565656;font-family: sans-serif;font-size: 16px;line-height: 25px;Margin-bottom: 24px">If you did not request this, please ignore this message.</p>

#includePartial("/common/email/footer")#
</cfoutput>
