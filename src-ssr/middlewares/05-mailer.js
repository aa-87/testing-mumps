import { writeFileSync, mkdirSync, existsSync } from 'node:fs'
import { join } from 'node:path'

function resolveOrigin(req) {
  // Prefer explicit env; otherwise infer from headers
  if (process.env.PUBLIC_BASE_URL) return process.env.PUBLIC_BASE_URL
  const proto = (req.headers['x-forwarded-proto'] || 'http').split(',')[0]
  const host = req.headers['x-forwarded-host'] || req.headers.host
  return `${proto}://${host}`
}

export default function () {
  const outDir = join(process.cwd(), 'data', 'mails')
  if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true })

  return (req, _res, next) => {
    req.$mailer = {
      async send({ to, subject, html }) {
        const fname = join(
          outDir,
          `${Date.now()}-${(to || '').replace(/[^a-z0-9@._-]/gi, '_')}.html`,
        )
        writeFileSync(fname, `<h3>${subject}</h3>\n${html}`)

        console.log(
          '[MAIL->%s] %s\n%s\nSaved: %s',
          to,
          subject,
          html.replace(/<[^>]+>/g, ''),
          fname,
        )
      },
      origin: resolveOrigin(req),
    }
    next()
  }
}
