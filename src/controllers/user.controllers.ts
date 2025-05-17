import type { Request, Response } from 'express'
import { PrismaClient } from 'generated/prisma/index';

const prisma = new PrismaClient()

const user = {
    allUsers: async (_req: Request, res: Response) => {
        try {
            const allUsers = await prisma.user.findMany()
            res.json(
                {
                    message: 'Liste des utilisateurs',
                    content: allUsers,
                    state: 1,
                }
            );
        } catch (error) {
            res.json(`Internal Server Error: ${error}`)
        }
    }
}

export default user;