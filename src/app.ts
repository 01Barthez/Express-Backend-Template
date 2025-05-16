import express from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
import userRoutes from './routes/user.routes'

dotenv.config()

const app = express()

// Middlewares
app.use(cors())
app.use(express.json())

// Exemple de route
app.get('/', (_req, res) => {
    res.send('Hello, Barthez Backend is running!')
})

app.use('/api/v1/users', userRoutes)

export default app
