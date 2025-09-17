import express from 'express'
import helmet from 'helmet'
import morgan from 'morgan'
import cors from 'cors'
import crypto from 'crypto'
import rateLimit from 'express-rate-limit'
import axios from 'axios'
import 'dotenv/config'

const app = express()
app.use(helmet({ contentSecurityPolicy: false }))
app.use(express.json({ limit: '256kb' }))
app.use(morgan('combined'))
app.use(cors({ origin: process.env.ALLOWED_ORIGIN?.split(',') || true }))

const limiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 100 })
app.use('/v1/', limiter)

function verifyHMAC(req, res, next) {
  const secret = process.env.HMAC_SECRET
  if (!secret) return res.status(500).json({ error: 'Server not configured' })
  const signature = req.header('X-Signature') || ''
  const hmac = crypto.createHmac('sha256', secret)
  const body = JSON.stringify(req.body)
  const digest = hmac.update(body).digest('hex')
  if (crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(digest))) return next()
  return res.status(401).json({ error: 'Invalid signature' })
}

app.post('/v1/validate/apple', verifyHMAC, async (req, res) => {
  try {
    const { receipt, bundleId } = req.body || {}
    if (!receipt || !bundleId) return res.status(400).json({ error: 'Missing fields' })

    const endpoint = process.env.APPLE_ENV === 'production'
      ? 'https://buy.itunes.apple.com/verifyReceipt'
      : 'https://sandbox.itunes.apple.com/verifyReceipt'

    const response = await axios.post(endpoint, {
      'receipt-data': receipt,
      'exclude-old-transactions': true
    }, { timeout: 8000 })

    // NOTE: In production, verify bundle_id, product_id and status per Apple docs
    const data = response.data
    if (data.status === 0) {
      return res.json({ valid: true })
    }
    return res.status(400).json({ valid: false, status: data.status })
  } catch (err) {
    return res.status(500).json({ error: 'Validation error' })
  }
})

app.get('/healthz', (_req, res) => res.json({ ok: true }))

const port = process.env.PORT || 8080
app.listen(port, () => console.log(`lifeos-backend listening on ${port}`))

