import user from '@src/controllers/user.controllers'
import { Router } from 'express'

const userRoutes = Router()

userRoutes.get('/users', user.allUsers)

export default userRoutes
