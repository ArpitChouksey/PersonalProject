from pathlib import Path


class DocumentLoader:

    def __init__(
        self,
        documents_directory: str = "app/rag/documents",
    ):
        self.documents_directory = Path(
            documents_directory
        )

    def load(self) -> list[dict]:

        documents = []

        for file_path in self.documents_directory.glob(
            "*.txt"
        ):

            content = file_path.read_text(
                encoding="utf-8"
            )

            documents.append(
                {
                    "source": file_path.name,
                    "content": content,
                }
            )

        return documents
