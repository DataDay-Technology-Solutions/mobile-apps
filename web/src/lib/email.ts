import { Resend } from 'resend'
import { log } from './logger'

const resend = new Resend(process.env.RESEND_API_KEY)

const FROM_EMAIL = process.env.FROM_EMAIL || 'Hall Pass <noreply@hallpassedu.com>'

interface SendEmailOptions {
  to: string | string[]
  subject: string
  html: string
  text?: string
}

export async function sendEmail({ to, subject, html, text }: SendEmailOptions) {
  try {
    const { data, error } = await resend.emails.send({
      from: FROM_EMAIL,
      to: Array.isArray(to) ? to : [to],
      subject,
      html,
      text,
    })

    if (error) {
      log.error('Failed to send email', error, { to, subject })
      throw error
    }

    log.info('Email sent successfully', { to, subject, id: data?.id })
    return data
  } catch (error) {
    log.error('Email service error', error, { to, subject })
    throw error
  }
}

// Pre-built email templates
export const emailTemplates = {
  // Welcome email for new users
  welcome: (name: string, role: 'teacher' | 'parent') => ({
    subject: `Welcome to Hall Pass, ${name}!`,
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="text-align: center; margin-bottom: 30px;">
            <div style="display: inline-block; background: linear-gradient(135deg, #3b82f6, #6366f1); padding: 15px; border-radius: 16px;">
              <span style="font-size: 32px;">🎓</span>
            </div>
          </div>

          <h1 style="color: #1f2937; text-align: center; margin-bottom: 20px;">
            Welcome to Hall Pass!
          </h1>

          <p style="font-size: 16px; color: #4b5563;">
            Hi ${name},
          </p>

          <p style="font-size: 16px; color: #4b5563;">
            ${role === 'teacher'
              ? "You're all set to create your classroom and start connecting with parents. Here's what you can do:"
              : "You're ready to stay connected with your child's classroom. Here's what you can do:"
            }
          </p>

          <ul style="font-size: 16px; color: #4b5563; padding-left: 20px;">
            ${role === 'teacher' ? `
              <li>Create classrooms and invite parents</li>
              <li>Share stories and updates</li>
              <li>Track student behavior with points</li>
              <li>Message parents directly</li>
            ` : `
              <li>View your child's classroom updates</li>
              <li>See stories and achievements</li>
              <li>Message teachers directly</li>
              <li>Track your child's progress</li>
            `}
          </ul>

          <div style="text-align: center; margin: 30px 0;">
            <a href="https://hallpassedu.com/dashboard" style="display: inline-block; background: linear-gradient(135deg, #3b82f6, #6366f1); color: white; padding: 14px 28px; border-radius: 12px; text-decoration: none; font-weight: 600; font-size: 16px;">
              Get Started
            </a>
          </div>

          <p style="font-size: 14px; color: #9ca3af; text-align: center; margin-top: 40px;">
            Questions? Reply to this email and we'll help you out.
          </p>

          <div style="border-top: 1px solid #e5e7eb; margin-top: 30px; padding-top: 20px; text-align: center;">
            <p style="font-size: 12px; color: #9ca3af;">
              Hall Pass - Connecting Teachers, Parents & Students<br>
              <a href="https://hallpassedu.com" style="color: #6366f1;">hallpassedu.com</a>
            </p>
          </div>
        </body>
      </html>
    `,
    text: `Welcome to Hall Pass, ${name}!\n\nYou're all set to ${role === 'teacher' ? 'create your classroom' : 'connect with your child\'s classroom'}.\n\nGet started: https://hallpassedu.com/dashboard`,
  }),

  // Class join notification for teachers
  parentJoined: (teacherName: string, parentName: string, className: string, studentName: string) => ({
    subject: `${parentName} joined ${className}`,
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
        </head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #1f2937;">New Parent Joined! 🎉</h2>

          <p>Hi ${teacherName},</p>

          <p><strong>${parentName}</strong> has joined <strong>${className}</strong> as a parent of <strong>${studentName}</strong>.</p>

          <p>You can now message them directly through Hall Pass.</p>

          <div style="margin: 25px 0;">
            <a href="https://hallpassedu.com/messages" style="display: inline-block; background: #3b82f6; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: 500;">
              View Messages
            </a>
          </div>

          <p style="font-size: 14px; color: #6b7280;">— Hall Pass</p>
        </body>
      </html>
    `,
    text: `New Parent Joined!\n\n${parentName} has joined ${className} as a parent of ${studentName}.\n\nView messages: https://hallpassedu.com/messages`,
  }),

  // New message notification
  newMessage: (recipientName: string, senderName: string, preview: string) => ({
    subject: `New message from ${senderName}`,
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
        </head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #1f2937;">New Message 💬</h2>

          <p>Hi ${recipientName},</p>

          <p>You have a new message from <strong>${senderName}</strong>:</p>

          <div style="background: #f3f4f6; border-left: 4px solid #3b82f6; padding: 15px; margin: 20px 0; border-radius: 0 8px 8px 0;">
            <p style="margin: 0; color: #4b5563;">"${preview}..."</p>
          </div>

          <div style="margin: 25px 0;">
            <a href="https://hallpassedu.com/messages" style="display: inline-block; background: #3b82f6; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: 500;">
              Reply Now
            </a>
          </div>

          <p style="font-size: 14px; color: #6b7280;">— Hall Pass</p>
        </body>
      </html>
    `,
    text: `New message from ${senderName}:\n\n"${preview}..."\n\nReply: https://hallpassedu.com/messages`,
  }),

  // Points milestone notification for parents
  pointsMilestone: (parentName: string, studentName: string, points: number, milestone: string) => ({
    subject: `🌟 ${studentName} reached ${points} points!`,
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
        </head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="text-align: center; margin-bottom: 20px;">
            <span style="font-size: 48px;">🌟</span>
          </div>

          <h2 style="color: #1f2937; text-align: center;">Achievement Unlocked!</h2>

          <p>Hi ${parentName},</p>

          <p>Great news! <strong>${studentName}</strong> has reached <strong>${points} points</strong> and earned the <strong>${milestone}</strong> milestone!</p>

          <p>Keep up the amazing work! 🎉</p>

          <div style="margin: 25px 0; text-align: center;">
            <a href="https://hallpassedu.com/points" style="display: inline-block; background: linear-gradient(135deg, #f59e0b, #ef4444); color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: 500;">
              View Progress
            </a>
          </div>

          <p style="font-size: 14px; color: #6b7280;">— Hall Pass</p>
        </body>
      </html>
    `,
    text: `Achievement Unlocked!\n\n${studentName} has reached ${points} points and earned the ${milestone} milestone!\n\nView progress: https://hallpassedu.com/points`,
  }),
}

// Convenience functions
export async function sendWelcomeEmail(email: string, name: string, role: 'teacher' | 'parent') {
  const template = emailTemplates.welcome(name, role)
  return sendEmail({ to: email, ...template })
}

export async function sendParentJoinedEmail(
  teacherEmail: string,
  teacherName: string,
  parentName: string,
  className: string,
  studentName: string
) {
  const template = emailTemplates.parentJoined(teacherName, parentName, className, studentName)
  return sendEmail({ to: teacherEmail, ...template })
}

export async function sendNewMessageEmail(
  recipientEmail: string,
  recipientName: string,
  senderName: string,
  messagePreview: string
) {
  const template = emailTemplates.newMessage(recipientName, senderName, messagePreview)
  return sendEmail({ to: recipientEmail, ...template })
}

export async function sendPointsMilestoneEmail(
  parentEmail: string,
  parentName: string,
  studentName: string,
  points: number,
  milestone: string
) {
  const template = emailTemplates.pointsMilestone(parentName, studentName, points, milestone)
  return sendEmail({ to: parentEmail, ...template })
}
