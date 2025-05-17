import type { Request, Response } from 'express'


const hello = (_req: Request, res: Response) => {
    res.json({ message: 'Hello EveryOne, Your Backend is running !' });
}

export default hello;