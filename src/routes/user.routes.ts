import { Router } from 'express'

const router = Router()

router.get('/', (_req, res) => {
    res.json({ message: 'Liste des utilisateurs' })
})

export default router
