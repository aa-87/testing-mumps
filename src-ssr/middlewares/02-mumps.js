// src-ssr/middlewares/02-mumps.js
import { createMumpsClient } from '../mumpsClient.js'

export default function () {
  const client = createMumpsClient()
  return (req, _res, next) => {
    req.$m = client
    next()
  }
}
