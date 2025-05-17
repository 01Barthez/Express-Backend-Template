import express from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
import userRoutes from './routes/user.routes'
import helloRoutes from './routes/hello.routes'
import health from './routes/health.routes'

dotenv.config()

const app = express()

// Middlewares
app.use(cors())
app.use(express.json())

app.use('/', helloRoutes)
app.use('/api/v1/users', userRoutes)
app.use('/', health)

export default app
