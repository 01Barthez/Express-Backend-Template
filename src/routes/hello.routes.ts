import hello from '@src/controllers/hello.controllers'
import { Router } from 'express'

const helloRoutes = Router()

helloRoutes.get('/hello', hello)

export default helloRoutes
