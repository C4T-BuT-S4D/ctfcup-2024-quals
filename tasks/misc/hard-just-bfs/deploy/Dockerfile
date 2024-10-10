FROM python:3.12

COPY OCRB.ttf /usr/share/fonts/

WORKDIR /app
COPY requirments.txt ./
RUN pip install -r requirments.txt
COPY . ./

CMD ["python", "olymp_problem.py"]
